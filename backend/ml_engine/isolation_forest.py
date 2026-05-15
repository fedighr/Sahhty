import pickle
import numpy as np
import pandas as pd
from pathlib import Path
from filelock import FileLock
from django.db.models import Count
from dateutil.relativedelta import relativedelta
from sklearn.ensemble import IsolationForest

BASE_DIR = Path(__file__).resolve().parent
SOURCES_DIR = BASE_DIR.parent / "sources"
DATASET_PATH = SOURCES_DIR / "Maternal Health Risk Data Set.csv"
PERSONAL_MODELS_DIR = BASE_DIR / "personal_models"

PERSONAL_MODELS_DIR.mkdir(exist_ok=True)

RAW_FEATURE_COLUMNS = ["SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate"]

KAGGLE_WEIGHT = 0.3
PERSONAL_WEIGHT = 0.7
KAGGLE_SIZE = 1014

CONTAMINATION = 0.1
RETRAIN_EVERY_N_ROWS = 5
ANOMALY_THRESHOLD = -0.5
STAGE_CENTER = 150

MIN_READINGS_PER_TYPE = {
    "BLOOD_PRESSURE": 10,
    "GLYCEMIA":       10,
    "HEART_RATE":     8,
    "TEMPERATURE":    5,
}


def add_features(df: pd.DataFrame, age: int, pregnancy_week: int) -> pd.DataFrame:
    df = df.copy()
    df["Age"]           = age
    df["PregnancyWeek"] = pregnancy_week
    df["Trimester"]     = pd.cut(
        pd.Series([pregnancy_week]),
        bins=[0, 12, 26, 42],
        labels=[1, 2, 3],
        include_lowest=True,
    ).astype(int).values[0]
    df["PulsePressure"] = df["SystolicBP"] - df["DiastolicBP"]
    df["BP_Ratio"]      = df["SystolicBP"] / (df["DiastolicBP"] + 1e-6)
    df["MAP"]           = (2 * df["DiastolicBP"] + df["SystolicBP"]) / 3
    df["ShockIndex"]    = df["HeartRate"] / (df["SystolicBP"] + 1e-6)
    df["TempHigh"]      = (df["BodyTemp"] >= 101).astype(int)
    df["BS_High"]       = (df["BS"] >= 8.0).astype(int)
    df["HR_BP_Ratio"]   = df["HeartRate"] / (df["DiastolicBP"] + 1e-6)
    df["BS_Temp"]       = df["BS"] * df["BodyTemp"]
    df["BP_Age"]        = df["SystolicBP"] * age
    df["AgeGroup"]      = pd.cut(
        df["Age"],
        bins=[0, 20, 30, 40, 50, 60, 100],
        labels=False,
        include_lowest=True,
    ).fillna(0).astype(int)
    return df


def convert_to_model_units(bp_sys, bp_dia, glucose_gl, body_temp_c, heart_rate):
    return {
        "SystolicBP":  float(bp_sys),
        "DiastolicBP": float(bp_dia),
        "BS":          round(float(glucose_gl) * 5.55, 2),
        "BodyTemp":    round(float(body_temp_c) * 9 / 5 + 32, 2),
        "HeartRate":   float(heart_rate),
    }


def get_personal_model_path(patient_id):
    return PERSONAL_MODELS_DIR / f"patient_{patient_id}.pkl"


def load_personal_model(patient_id):
    path = get_personal_model_path(patient_id)
    if not path.exists():
        return None
    with FileLock(str(path) + ".lock"):
        with open(path, "rb") as f:
            return pickle.load(f)


def save_personal_model(patient_id, model):
    path = get_personal_model_path(patient_id)
    with FileLock(str(path) + ".lock"):
        with open(path, "wb") as f:
            pickle.dump(model, f)


def has_enough_data(patient_id) -> bool:
    from measurements.models import Measurement

    counts = (
        Measurement.objects
        .filter(patient_id=patient_id, type__in=MIN_READINGS_PER_TYPE.keys())
        .values("type")
        .annotate(count=Count("id"))
    )

    counts_dict = {row["type"]: row["count"] for row in counts}

    return all(
        counts_dict.get(mtype, 0) >= minimum
        for mtype, minimum in MIN_READINGS_PER_TYPE.items()
    )


def should_retrain(patient_id) -> bool:
    from measurements.models import RiskAssessment, IFRetrainLog

    last_retrain = (
        IFRetrainLog.objects
        .filter(patient_id=patient_id)
        .order_by("-retrained_at")
        .first()
    )

    if last_retrain is None:
        return True

    count_since = RiskAssessment.objects.filter(
        patient_id=patient_id,
        assessed_at__gt=last_retrain.retrained_at,
    ).count()

    return count_since >= RETRAIN_EVERY_N_ROWS


def load_kaggle_data() -> pd.DataFrame:
    df = pd.read_csv(DATASET_PATH)
    df.columns = [c.strip() for c in df.columns]
    df = df[RAW_FEATURE_COLUMNS + ["Age"]].dropna()

    processed_rows = []
    for _, row in df.iterrows():
        row_df = pd.DataFrame([row[RAW_FEATURE_COLUMNS]])
        row_df = add_features(row_df, age=int(row["Age"]), pregnancy_week=20)
        processed_rows.append(row_df)

    return pd.concat(processed_rows, ignore_index=True)


def get_patient_measurements(patient_id) -> pd.DataFrame | None:
    from measurements.models import RiskAssessment

    records = RiskAssessment.objects.filter(
        patient_id=patient_id,
        bp_sys_used__isnull=False,
        bp_dia_used__isnull=False,
        glucose_used__isnull=False,
        body_temp_used__isnull=False,
        heart_rate_used__isnull=False,
    ).select_related("patient__user").order_by("assessed_at").values(
        "bp_sys_used",
        "bp_dia_used",
        "glucose_used",
        "body_temp_used",
        "heart_rate_used",
        "assessed_at",
        "patient__user__birth_date",
        "pregnancy_week",
    )

    if not records:
        return None

    processed_rows = []
    for record in records:
        age = relativedelta(
            record["assessed_at"].date(),
            record["patient__user__birth_date"]
        ).years

        converted = convert_to_model_units(
            bp_sys=record["bp_sys_used"],
            bp_dia=record["bp_dia_used"],
            glucose_gl=record["glucose_used"],
            body_temp_c=record["body_temp_used"],
            heart_rate=record["heart_rate_used"],
        )

        row_df = pd.DataFrame([converted])
        row_df = add_features(row_df, age=age, pregnancy_week=record["pregnancy_week"] or 20)
        processed_rows.append(row_df)

    if not processed_rows:
        return None

    return pd.concat(processed_rows, ignore_index=True)


def train_personal_model(patient_id):
    from measurements.models import IFRetrainLog

    personal_data = get_patient_measurements(patient_id)
    if personal_data is None:
        return None

    kaggle_data = load_kaggle_data()

    patient_weight_per_row = PERSONAL_WEIGHT / len(personal_data)
    kaggle_weight_per_row  = KAGGLE_WEIGHT / KAGGLE_SIZE

    combined = pd.concat([personal_data, kaggle_data], ignore_index=True)
    weights  = (
        [patient_weight_per_row] * len(personal_data) +
        [kaggle_weight_per_row]  * len(kaggle_data)
    )

    model = IsolationForest(contamination=CONTAMINATION, random_state=42, n_jobs=-1)
    model.fit(combined, sample_weight=weights)

    save_personal_model(patient_id, model)
    IFRetrainLog.objects.create(patient_id=patient_id)

    return model


def combine_risks(global_risk: str, if_score: float) -> str:
    if if_score >= ANOMALY_THRESHOLD:
        return global_risk

    upgrade = {"LOW": "MEDIUM", "MEDIUM": "HIGH", "HIGH": "HIGH"}
    return upgrade[global_risk]


def predict_personal_risk(
    patient_id,
    measurements,
    birth_date,
    assessed_at,
    pregnancy_week,
    total_assessments,
    global_risk: str,
) -> str:
    if not has_enough_data(patient_id):
        return global_risk

    model = load_personal_model(patient_id)
    if model is None:
        model = train_personal_model(patient_id)
    if model is None:
        return global_risk

    age = relativedelta(assessed_at.date(), birth_date).years

    converted = convert_to_model_units(
        bp_sys=measurements["SystolicBP"],
        bp_dia=measurements["DiastolicBP"],
        glucose_gl=measurements["BS"],
        body_temp_c=measurements["BodyTemp"],
        heart_rate=measurements["HeartRate"],
    )

    input_df = pd.DataFrame([converted])
    input_df = add_features(input_df, age=age, pregnancy_week=pregnancy_week)

    score = model.score_samples(input_df)[0]

    final_risk = combine_risks(global_risk, score)

    priority = {"LOW": 0, "MEDIUM": 1, "HIGH": 2}

    if total_assessments < STAGE_CENTER:
        final_risk = max(global_risk, final_risk, key=lambda x: priority[x])

    if should_retrain(patient_id):
        train_personal_model(patient_id)

    return final_risk