import os
import pickle

import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def load_artifacts():
    with open(os.path.join(BASE_DIR, "pregnancy_rf_classifier.pkl"), "rb") as f:
        classifier_model = pickle.load(f)
    with open(os.path.join(BASE_DIR, "pregnancy_rf_regressor.pkl"), "rb") as f:
        regressor_model = pickle.load(f)
    with open(os.path.join(BASE_DIR, "label_encoder.pkl"), "rb") as f:
        encoder = pickle.load(f)
    with open(os.path.join(BASE_DIR, "heart_rate_median.pkl"), "rb") as f:
        hr_median = pickle.load(f)

    preprocess = {
        "heart_rate_median": float(hr_median),
        "feature_columns": [
            "age",
            "bmi",
            "glucose",
            "blood_pressure_sys",
            "blood_pressure_dia",
            "pregnancy_week",
            "heart_rate",
        ],
    }
    return classifier_model, regressor_model, encoder, preprocess


classifier, regressor, label_encoder, preprocess_config = load_artifacts()
heart_rate_median = float(preprocess_config.get("heart_rate_median", 85.0))
feature_columns = preprocess_config.get(
    "feature_columns",
    ["age", "bmi", "glucose", "blood_pressure_sys", "blood_pressure_dia", "pregnancy_week", "heart_rate"],
)

BOUNDS = {
    "age": (12, 60),
    "bmi": (12.0, 60.0),
    "glucose": (30.0, 350.0),
    "blood_pressure_sys": (60.0, 260.0),
    "blood_pressure_dia": (30.0, 160.0),
    "pregnancy_week": (1, 42),
    "heart_rate": (35.0, 220.0),
}


def validate_and_prepare_input(data):
    if not isinstance(data, dict):
        raise ValueError("Input must be a dictionary")

    required = ["age", "bmi", "glucose", "blood_pressure_sys", "blood_pressure_dia", "pregnancy_week"]
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

    age = parse_number("age", data.get("age"))
    bmi = parse_number("bmi", data.get("bmi"))
    glucose = parse_number("glucose", data.get("glucose"))
    blood_pressure_sys = parse_number("blood_pressure_sys", data.get("blood_pressure_sys"))
    blood_pressure_dia = parse_number("blood_pressure_dia", data.get("blood_pressure_dia"))
    pregnancy_week = parse_number("pregnancy_week", data.get("pregnancy_week"))

    heart_rate_value = data.get("heart_rate", None)
    if heart_rate_value is None:
        heart_rate = float(heart_rate_median)
    else:
        heart_rate = parse_number("heart_rate", heart_rate_value)

    values = {
        "age": age,
        "bmi": bmi,
        "glucose": glucose,
        "blood_pressure_sys": blood_pressure_sys,
        "blood_pressure_dia": blood_pressure_dia,
        "pregnancy_week": pregnancy_week,
        "heart_rate": heart_rate,
    }

    for field_name, value in values.items():
        if value is None:
            continue
        low, high = BOUNDS[field_name]
        if not (low <= value <= high):
            errors.append(f"{field_name} out of physiologic bounds [{low}, {high}]")

    if values["blood_pressure_sys"] is not None and values["blood_pressure_dia"] is not None:
        if values["blood_pressure_sys"] <= values["blood_pressure_dia"]:
            errors.append("blood_pressure_sys must be greater than blood_pressure_dia")

    if errors:
        raise ValueError("; ".join(errors))

    return {
        "age": int(round(values["age"])),
        "bmi": round(values["bmi"], 2),
        "glucose": round(values["glucose"], 2),
        "blood_pressure_sys": round(values["blood_pressure_sys"], 2),
        "blood_pressure_dia": round(values["blood_pressure_dia"], 2),
        "pregnancy_week": int(round(values["pregnancy_week"])),
        "heart_rate": round(values["heart_rate"], 2),
    }


def predict_risk(data):
    prepared = validate_and_prepare_input(data)

    patient = pd.DataFrame([{key: prepared[key] for key in feature_columns}])

    risk_percentage = round(float(regressor.predict(patient)[0]), 2)
    risk_percentage = max(0.0, min(100.0, risk_percentage))
    risk_level = label_encoder.inverse_transform(classifier.predict(patient))[0]

    if risk_percentage >= 60:
        percentage_level = "HIGH"
    elif risk_percentage >= 30:
        percentage_level = "MEDIUM"
    else:
        percentage_level = "LOW"

    priority = {"LOW": 1, "MEDIUM": 2, "HIGH": 3}
    final_level = risk_level if priority[risk_level] > priority[percentage_level] else percentage_level

    return final_level, risk_percentage, prepared["heart_rate"]