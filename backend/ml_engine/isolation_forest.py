import pickle
import numpy as np
import pandas as pd
from pathlib import Path
from dateutil.relativedelta import relativedelta
from sklearn.ensemble import IsolationForest

BASE_DIR = Path(__file__).resolve().parent
SOURCES_DIR = BASE_DIR.parent / "sources"
DATASET_PATH = SOURCES_DIR / "Maternal Health Risk Data Set.csv"
PERSONAL_MODELS_DIR = BASE_DIR / "personal_models"
PRETRAINED_PATH = BASE_DIR / "isolation_forest_pretrained.pkl"

PERSONAL_MODELS_DIR.mkdir(exist_ok=True)

RAW_FEATURE_COLUMNS = ["SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate"]

KAGGLE_WEIGHT = 0.3
PERSONAL_WEIGHT = 0.7

MIN_MEASUREMENTS = 15
MIN_PREGNANCY_WEEK = 13


def add_features(df: pd.DataFrame, age: int) -> pd.DataFrame:
    df = df.copy()
    df["Age"]           = age
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


def pretrain_on_kaggle():
    df = pd.read_csv(DATASET_PATH)
    df.columns = [c.strip() for c in df.columns]
    df = df[RAW_FEATURE_COLUMNS + ["Age"]].dropna()

    processed_rows = []
    for _, row in df.iterrows():
        row_df = pd.DataFrame([row[RAW_FEATURE_COLUMNS]])
        row_df = add_features(row_df, age=int(row["Age"]))
        processed_rows.append(row_df)

    full_df = pd.concat(processed_rows, ignore_index=True)

    model = IsolationForest(contamination=0.1, random_state=42, n_jobs=-1)
    model.fit(full_df)

    with open(PRETRAINED_PATH, "wb") as f:
        pickle.dump(model, f)

    return model


def load_pretrained():
    if not PRETRAINED_PATH.exists():
        return pretrain_on_kaggle()

    with open(PRETRAINED_PATH, "rb") as f:
        return pickle.load(f)


def get_personal_model_path(patient_id):
    return PERSONAL_MODELS_DIR / f"patient_{patient_id}.pkl"


def load_personal_model(patient_id):
    path = get_personal_model_path(patient_id)
    if not path.exists():
        return None

    with open(path, "rb") as f:
        return pickle.load(f)


def save_personal_model(patient_id, model):
    with open(get_personal_model_path(patient_id), "wb") as f:
        pickle.dump(model, f)


def get_patient_measurements(patient_id):
    from measurements.models import RiskAssessment

    records = RiskAssessment.objects.filter(
        patient_id=patient_id,
        bp_sys_used__isnull=False,
        bp_dia_used__isnull=False,
        glucose_used__isnull=False,
        body_temp_used__isnull=False,
        heart_rate_used__isnull=False,
    ).select_related("patient__user").values(
        "bp_sys_used",
        "bp_dia_used",
        "glucose_used",
        "body_temp_used",
        "heart_rate_used",
        "assessed_at",
        "patient__user__birth_date",
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
        row_df = add_features(row_df, age=age)
        processed_rows.append(row_df)

    if not processed_rows:
        return None

    return pd.concat(processed_rows, ignore_index=True)


def train_personal_model(patient_id):
    personal_data = get_patient_measurements(patient_id)
    if personal_data is None or len(personal_data) < MIN_MEASUREMENTS:
        return None

    kaggle_df = pd.read_csv(DATASET_PATH)
    kaggle_df.columns = [c.strip() for c in kaggle_df.columns]
    kaggle_df = kaggle_df[RAW_FEATURE_COLUMNS + ["Age"]].dropna()

    kaggle_processed = []
    for _, row in kaggle_df.iterrows():
        row_df = pd.DataFrame([row[RAW_FEATURE_COLUMNS]])
        row_df = add_features(row_df, age=int(row["Age"]))
        kaggle_processed.append(row_df)

    kaggle_full = pd.concat(kaggle_processed, ignore_index=True)

    n_kaggle = len(kaggle_full)
    repeat_times = int(np.ceil((n_kaggle * PERSONAL_WEIGHT) / (len(personal_data) * KAGGLE_WEIGHT)))
    personal_repeated = pd.concat([personal_data] * repeat_times, ignore_index=True)

    combined = pd.concat([kaggle_full, personal_repeated], ignore_index=True)

    model = IsolationForest(contamination=0.15, random_state=42, n_jobs=-1)
    model.fit(combined)

    save_personal_model(patient_id, model)
    return model


def score_to_risk(score: float) -> str:
    if score >= -0.46:
        return "LOW"
    elif score >= -0.53:
        return "MEDIUM"
    else:
        return "HIGH"


def predict_personal_risk(patient_id, measurements, birth_date, assessed_at, pregnancy_week, total_assessments):
    if pregnancy_week is None or pregnancy_week < MIN_PREGNANCY_WEEK or total_assessments < MIN_MEASUREMENTS:
        return None

    model = load_personal_model(patient_id)
    if model is None:
        model = train_personal_model(patient_id)
    if model is None:
        return None

    age = relativedelta(assessed_at.date(), birth_date).years

    converted = convert_to_model_units(
        bp_sys=measurements["SystolicBP"],
        bp_dia=measurements["DiastolicBP"],
        glucose_gl=measurements["BS"],
        body_temp_c=measurements["BodyTemp"],
        heart_rate=measurements["HeartRate"],
    )

    input_df = pd.DataFrame([converted])
    input_df = add_features(input_df, age=age)

    score = model.score_samples(input_df)[0]
    risk  = score_to_risk(score)

    train_personal_model(patient_id)

    return risk


def get_final_risk(global_risk: str, personal_risk) -> str:
    priority = {"LOW": 0, "MEDIUM": 1, "HIGH": 2}

    if personal_risk is None:
        return global_risk

    return max(global_risk, personal_risk, key=lambda x: priority[x])