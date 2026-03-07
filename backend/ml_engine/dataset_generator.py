import numpy as np
import pandas as pd

N_LOW    = 1200
N_MEDIUM = 900
N_HIGH   = 600
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

data = []

def generate_patient(risk_level):
    if risk_level == "LOW":
        age            = np.random.randint(18, 30)
        bmi            = np.random.normal(22, 1.5)
        glucose        = np.random.normal(82, 6)
        bp_sys         = np.random.normal(108, 6)
        bp_dia         = np.random.normal(68, 5)
        pregnancy_week = np.random.randint(1, 28)
        risk_pct_base  = np.random.uniform(5, 29)

    elif risk_level == "MEDIUM":
        age            = np.random.randint(25, 38)
        bmi            = np.random.normal(27, 2)
        glucose        = np.random.normal(100, 8)
        bp_sys         = np.random.normal(128, 7)
        bp_dia         = np.random.normal(82, 5)
        pregnancy_week = np.random.randint(10, 36)
        risk_pct_base  = np.random.uniform(30, 59)

    else:
        age            = np.random.randint(32, 46)
        bmi            = np.random.normal(32, 3)
        glucose        = np.random.normal(138, 15)
        bp_sys         = np.random.normal(148, 8)
        bp_dia         = np.random.normal(93, 6)
        pregnancy_week = np.random.randint(20, 41)
        risk_pct_base  = np.random.uniform(60, 95)

    bmi            = round(np.clip(bmi, 18.0, 42.0), 2)
    glucose        = round(np.clip(glucose, 70.0, 200.0), 2)
    bp_sys         = round(np.clip(bp_sys, 90.0, 170.0), 2)
    bp_dia         = round(np.clip(bp_dia, 55.0, 110.0), 2)

    if np.random.random() < 0.3:
        heart_rate = np.nan
    else:
        hr_base    = 80 if risk_level == "LOW" else (88 if risk_level == "MEDIUM" else 95)
        heart_rate = np.random.normal(hr_base, 7)
        heart_rate = round(np.clip(heart_rate, 60.0, 130.0), 2)

    risk_percentage = round(np.clip(risk_pct_base + np.random.normal(0, 3), 0, 100), 2)

    return [age, bmi, glucose, bp_sys, bp_dia, pregnancy_week,
            heart_rate, risk_percentage, risk_level]


for level, count in [("LOW", N_LOW), ("MEDIUM", N_MEDIUM), ("HIGH", N_HIGH)]:
    for _ in range(count):
        data.append(generate_patient(level))

np.random.shuffle(data)

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

print("=== Dataset distribution ===")
print(df["risk_level"].value_counts())
print(f"\nTotal rows: {len(df)}")
print(f"\nMissing heart_rate: {df['heart_rate'].isna().sum()} rows ({df['heart_rate'].isna().mean()*100:.1f}%)")
print("\n=== Feature ranges per risk level ===")
print(df.groupby("risk_level")[["age","bmi","glucose","blood_pressure_sys","blood_pressure_dia"]].mean().round(2))

df.to_csv("pregnancy_dataset.csv", index=False)
print("\n✅ pregnancy_dataset.csv saved successfully!")