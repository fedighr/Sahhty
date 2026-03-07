import pickle
import pandas as pd

import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(BASE_DIR, "pregnancy_rf_classifier.pkl"), "rb") as f:
    classifier = pickle.load(f)

with open(os.path.join(BASE_DIR, "pregnancy_rf_regressor.pkl"), "rb") as f:
    regressor = pickle.load(f)

with open(os.path.join(BASE_DIR, "label_encoder.pkl"), "rb") as f:
    label_encoder = pickle.load(f)

with open(os.path.join(BASE_DIR, "heart_rate_median.pkl"), "rb") as f:
    heart_rate_median = pickle.load(f)  


def predict(label, age, bmi, glucose, bp_sys, bp_dia, pregnancy_week, heart_rate=None):
    if heart_rate is None:
        heart_rate = heart_rate_median

    patient = pd.DataFrame([{
        "age": age,
        "bmi": bmi,
        "glucose": glucose,
        "blood_pressure_sys": bp_sys,
        "blood_pressure_dia": bp_dia,
        "pregnancy_week": pregnancy_week,
        "heart_rate": heart_rate
    }])

    risk_percentage = round(float(regressor.predict(patient)[0]), 2)
    risk_level = label_encoder.inverse_transform(classifier.predict(patient))[0]

    status = "✅" if risk_level == label else "❌"
    print(f"{status} {label:<8} → predicted: {risk_level:<8} | {risk_percentage}%")


predict("HIGH", age=28, bmi=26, glucose=130, bp_sys=135, bp_dia=88, pregnancy_week=20, heart_rate=95)
