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

def predict_risk(data):
  
    age = data['age']
    bmi = data['bmi']
    glucose = data['glucose']
    blood_pressure_sys = data['blood_pressure_sys']
    blood_pressure_dia = data['blood_pressure_dia']
    pregnancy_week = data['pregnancy_week']
    try:
        heart_rate = data['heart_rate']
    except:
            heart_rate = heart_rate_median

    patient = pd.DataFrame([{
    "age": age,
    "bmi": bmi,
    "glucose": glucose,
    "blood_pressure_sys": blood_pressure_sys,
    "blood_pressure_dia": blood_pressure_dia,
    "pregnancy_week": pregnancy_week,
    "heart_rate": heart_rate,
    }])

    risk_percentage = round(float(regressor.predict(patient)[0]),2)
    risk_level = label_encoder.inverse_transform(classifier.predict(patient))[0]

    if risk_percentage >= 60:
        percentage_level = "HIGH"
    elif risk_percentage >= 30:
        percentage_level = "MEDIUM"
    else:
        percentage_level = "LOW"

    priority = {"LOW": 1, "MEDIUM": 2, "HIGH": 3}
    final_level = risk_level if priority[risk_level] > priority[percentage_level] else percentage_level

    return final_level, risk_percentage, heart_rate

