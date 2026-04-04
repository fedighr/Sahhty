import os
import pickle

import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def load_artifacts():
    with open(os.path.join(BASE_DIR, "best_model.pkl"), "rb") as f:
        classifier_model = pickle.load(f)
    with open(os.path.join(BASE_DIR, "label_encoder.pkl"), "rb") as f:
        encoder = pickle.load(f)
    with open(os.path.join(BASE_DIR, "heart_rate_median.pkl"), "rb") as f:
        hr_median = pickle.load(f)

    preprocess = {
        "heart_rate_median": float(hr_median),
        "feature_columns": [
            "Age",
            "BS",
            "SystolicBP",
            "DiastolicBP",
            "HeartRate",
            "BodyTemp"
        ],
    }
    return classifier_model, encoder, preprocess


classifier, label_encoder, preprocess_config = load_artifacts()
heart_rate_median = float(preprocess_config.get("heart_rate_median", 85.0))

BOUNDS = {
    "Age": (12, 60),
    "BS": (1.67, 19.44),
    "SystolicBP": (60.0, 260.0),
    "DiastolicBP": (30.0, 160.0),
    "HeartRate": (35.0, 220.0),
    "BodyTemp": (96.8, 107.6),
}


def validate_and_prepare_input(data):
    if not isinstance(data, dict):
        raise ValueError("Input must be a dictionary")

    required = ["Age", "BS", "SystolicBP", "DiastolicBP"]
    missing = [field for field in required if field not in data or data[field] is None]
    if missing:
        raise ValueError("Missing required fields: " + ", ".join(missing))

    errors = []

    def parse_number(field_name, value):
        try:
            return float(value)
        except (TypeError, ValueError):
            errors.append(f"Invalid type for {field_name}: expected numeric")
            return None

    age        = parse_number("Age",        data.get("Age"))
    bs = parse_number("BS", data.get("BS"))
    if bs is not None and bs > 30:
        bs = round(bs / 18.0, 2)
    systolic   = parse_number("SystolicBP", data.get("SystolicBP"))
    diastolic  = parse_number("DiastolicBP",data.get("DiastolicBP"))
    body_temp_value = data.get("BodyTemp", None)
    body_temp = 98.6 if body_temp_value is None else parse_number("BodyTemp", body_temp_value)
    if body_temp is not None and body_temp < 45:
        body_temp = round(float(body_temp * 9/5 + 32), 2)

    heart_rate_value = data.get("HeartRate", None)
    heart_rate = float(heart_rate_median) if heart_rate_value is None else parse_number("HeartRate", heart_rate_value)

    values = {
        "Age":        age,
        "BS":         bs,
        "SystolicBP": systolic,
        "DiastolicBP":diastolic,
        "HeartRate":  heart_rate,
        "BodyTemp":   body_temp,
    }

    for field_name, value in values.items():
        if value is None:
            continue
        low, high = BOUNDS[field_name]
        if not (low <= value <= high):
            errors.append(f"{field_name} out of physiologic bounds [{low}, {high}]")

    if systolic is not None and diastolic is not None:
        if systolic <= diastolic:
            errors.append("SystolicBP must be greater than DiastolicBP")

    if errors:
        raise ValueError("; ".join(errors))

    return {
        "Age":        int(round(values["Age"])),
        "BS":         round(values["BS"], 2),
        "SystolicBP": round(values["SystolicBP"], 2),
        "DiastolicBP":round(values["DiastolicBP"], 2),
        "HeartRate":  round(values["HeartRate"], 2),
        "BodyTemp":   round(values["BodyTemp"], 2),
    }

def add_features(df):
    df = df.copy()
    df["PulsePressure"] = df["SystolicBP"] - df["DiastolicBP"]
    df["BP_Ratio"] = df["SystolicBP"] / (df["DiastolicBP"] + 1e-6)
    df["MAP"] = (2 * df["DiastolicBP"] + df["SystolicBP"]) / 3
    df["ShockIndex"] = df["HeartRate"] / (df["SystolicBP"] + 1e-6)
    df["TempHigh"] = (df["BodyTemp"] >= 101).astype(int)
    df["BS_High"] = (df["BS"] >= 8.0).astype(int)
    df["HR_BP_Ratio"] = df["HeartRate"] / (df["DiastolicBP"] + 1e-6)
    df["BS_Temp"] = df["BS"] * df["BodyTemp"]
    df["BP_Age"] = df["SystolicBP"] * df["Age"]
    df["AgeGroup"] = pd.cut(
        df["Age"],
        bins=[0, 20, 30, 40, 50, 60, 100],
        labels=False,
        include_lowest=True
    ).fillna(0).astype(int)
    return df

def predict_risk(data):
    prepared = validate_and_prepare_input(data)

    base_columns = ["Age", "BS", "SystolicBP", "DiastolicBP", "HeartRate", "BodyTemp"]
    patient = pd.DataFrame([{key: prepared[key] for key in base_columns}])
    patient = add_features(patient)

    model_columns = [
        "Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate",
        "PulsePressure", "BP_Ratio", "MAP", "ShockIndex", "TempHigh",
        "BS_High", "HR_BP_Ratio", "BS_Temp", "BP_Age", "AgeGroup"
    ]
    patient = patient[model_columns]

    risk_level = label_encoder.inverse_transform(classifier.predict(patient))[0]
    return risk_level, prepared["HeartRate"]