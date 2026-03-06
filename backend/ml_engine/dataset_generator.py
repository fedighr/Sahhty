import numpy as np
import pandas as pd

N = 2500

data = []

for _ in range(N):

    age = np.random.randint(18, 46)

    bmi = np.random.normal(24 + age * 0.05, 3)
    bmi = np.clip(bmi, 18, 40)
    bmi = round(bmi, 2)

    glucose = np.random.normal(90 + bmi * 1.2 + age * 0.3, 15)
    glucose = np.clip(glucose, 70, 180)
    glucose = round(glucose, 2)

    bp_sys = np.random.normal(100 + age * 0.8 + bmi * 0.5, 10)
    bp_sys = np.clip(bp_sys, 90, 160)
    bp_sys = round(bp_sys, 2)

    bp_dia = np.random.normal(65 + age * 0.4 + bmi * 0.3, 8)
    bp_dia = np.clip(bp_dia, 60, 100)
    bp_dia = round(bp_dia, 2)

    pregnancy_week = np.random.randint(1, 41)

    if np.random.random() < 0.3:
        heart_rate = np.nan
    else:
        heart_rate = np.random.normal(80 + age * 0.1, 8)
        heart_rate = np.clip(heart_rate, 60, 120)
    heart_rate = round(heart_rate, 2)    

    risk_score = (
        0.25 * (age / 45) +
        0.25 * (bmi / 40) +
        0.2 * (glucose / 180) +
        0.15 * (bp_sys / 160) +
        0.15 * (pregnancy_week / 40)
    )

    risk_percentage = np.clip(risk_score * 100 + np.random.normal(0, 6), 0, 100)
    risk_percentage = round(risk_percentage, 2)

    if risk_percentage < 30:
        risk_level = "LOW"
    elif risk_percentage < 60:
        risk_level = "MEDIUM"
    else:
        risk_level = "HIGH"

    data.append([
        age,
        bmi,
        glucose,
        bp_sys,
        bp_dia,
        pregnancy_week,
        heart_rate,
        risk_percentage,
        risk_level
    ])

df = pd.DataFrame(data, columns=[
    "age",
    "bmi",
    "glucose",
    "blood_pressure_sys",
    "blood_pressure_dia",
    "pregnancy_week",
    "heart_rate",
    "risk_percentage",
    "risk_level"
])

df.to_csv("pregnancy_dataset.csv", index=False)