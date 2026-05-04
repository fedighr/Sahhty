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
            "BodyTemp",
        ],
    }
    return classifier_model, encoder, preprocess


classifier, label_encoder, preprocess_config = load_artifacts()
heart_rate_median = float(preprocess_config.get("heart_rate_median", 76.0))

STRICT_BOUNDS = {
    "SystolicBP":  (70.0,  160.0),
    "DiastolicBP": (49.0,  100.0),
    "BS":          (6.0,   19.0),
    "BodyTemp":    (98.0,  103.0),
}

BS_DANGER_LOW    = 3.3
BS_FLATTEN_LOW   = 6.0

TEMP_DANGER_LOW  = 96.8
TEMP_FLATTEN_LOW = 98.0

HR_MIN        = 40.0
HR_MAX_MODEL  = 90.0
HR_MAX_DANGER = 110.0

AGE_MIN_MODEL = 10
AGE_MAX_MODEL = 70


def validate_and_prepare_input(data):
    if not isinstance(data, dict):
        raise ValueError("Input must be a dictionary")

    required = ["Age", "BS", "SystolicBP", "DiastolicBP"]
    missing = [f for f in required if f not in data or data[f] is None]
    if missing:
        raise ValueError("Missing required fields: " + ", ".join(missing))

    errors = []

    def parse_number(field_name, value):
        try:
            return float(value)
        except (TypeError, ValueError):
            errors.append(f"Invalid type for {field_name}: expected numeric")
            return None

    age       = parse_number("Age",        data.get("Age"))
    bs        = parse_number("BS",         data.get("BS"))
    systolic  = parse_number("SystolicBP", data.get("SystolicBP"))
    diastolic = parse_number("DiastolicBP",data.get("DiastolicBP"))

    body_temp_value = data.get("BodyTemp", None)
    body_temp = 37.0 if body_temp_value is None else parse_number("BodyTemp", body_temp_value)

    heart_rate_value = data.get("HeartRate", None)
    heart_rate = float(heart_rate_median) if heart_rate_value is None else parse_number("HeartRate", heart_rate_value)

    if errors:
        raise ValueError("; ".join(errors))

    if bs is not None:
        bs = round(bs * 5.55, 2)

    if body_temp is not None:
        body_temp = round(body_temp * 9 / 5 + 32, 2)

    return {
        "Age":        age,
        "BS":         bs,
        "SystolicBP": systolic,
        "DiastolicBP":diastolic,
        "HeartRate":  heart_rate,
        "BodyTemp":   body_temp,
    }


def check_immediate_high_risk(values):
    bs = values.get("BS")
    if bs is not None and bs < BS_DANGER_LOW:
        print("Immediate high risk due to low BS", bs)
        return True

    temp = values.get("BodyTemp")
    if temp is not None and temp < TEMP_DANGER_LOW:
        print("Immediate high risk due to low body temperature", temp)
        return True

    hr = values.get("HeartRate")
    if hr is not None and (hr < HR_MIN or hr >= HR_MAX_DANGER):
        print("Immediate high risk due to abnormal heart rate", hr)
        return True

    for field, (low, high) in STRICT_BOUNDS.items():
        v = values.get(field)
        if v is None:
            continue
        if v > high:
            print("Immediate high risk due to high value in field", field)
            return True

    return False


def apply_flat_extrapolation(values):
    if values["Age"] is not None:
        values["Age"] = max(AGE_MIN_MODEL, min(values["Age"], AGE_MAX_MODEL))

    if values["HeartRate"] is not None:
        values["HeartRate"] = min(values["HeartRate"], HR_MAX_MODEL)

    if values["BS"] is not None and values["BS"] < BS_FLATTEN_LOW:
        values["BS"] = BS_FLATTEN_LOW

    if values["BodyTemp"] is not None and values["BodyTemp"] < TEMP_FLATTEN_LOW:
        values["BodyTemp"] = TEMP_FLATTEN_LOW

    return values


def add_features(df):
    df = df.copy()
    df["PulsePressure"] = df["SystolicBP"] - df["DiastolicBP"]
    df["BP_Ratio"]      = df["SystolicBP"] / (df["DiastolicBP"] + 1e-6)
    df["MAP"]           = (2 * df["DiastolicBP"] + df["SystolicBP"]) / 3
    df["ShockIndex"]    = df["HeartRate"] / (df["SystolicBP"] + 1e-6)
    df["TempHigh"]      = (df["BodyTemp"] >= 101).astype(int)
    df["BS_High"]       = (df["BS"] >= 8.0).astype(int)
    df["HR_BP_Ratio"]   = df["HeartRate"] / (df["DiastolicBP"] + 1e-6)
    df["BS_Temp"]       = df["BS"] * df["BodyTemp"]
    df["BP_Age"]        = df["SystolicBP"] * df["Age"]
    df["AgeGroup"]      = pd.cut(
        df["Age"],
        bins=[0, 20, 30, 40, 50, 60, 100],
        labels=False,
        include_lowest=True,
    ).fillna(0).astype(int)
    return df


def predict_risk(data):
    try:
        values = validate_and_prepare_input(data)
        print("Validated and prepared input:", values)

        if values["SystolicBP"] is not None and values["DiastolicBP"] is not None:
            if values["SystolicBP"] <= values["DiastolicBP"]:
                raise ValueError("SystolicBP must be greater than DiastolicBP")

        if check_immediate_high_risk(values):
            return "HIGH", values.get("HeartRate")

        values = apply_flat_extrapolation(values)

        base_columns = ["Age", "BS", "SystolicBP", "DiastolicBP", "HeartRate", "BodyTemp"]
        patient = pd.DataFrame([{key: values[key] for key in base_columns}])
        patient = add_features(patient)

        model_columns = [
            "Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate",
            "PulsePressure", "BP_Ratio", "MAP", "ShockIndex", "TempHigh",
            "BS_High", "HR_BP_Ratio", "BS_Temp", "BP_Age", "AgeGroup",
        ]
        patient = patient[model_columns]

        risk_level = label_encoder.inverse_transform(classifier.predict(patient))[0]
        return risk_level, values["HeartRate"]

    except ValueError:
        raise
    except Exception as e:
        raise RuntimeError(f"Prediction failed: {str(e)}") from e