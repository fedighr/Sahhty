import numpy as np
import pandas as pd

RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

TARGET_COUNTS = {"LOW": 1200, "MEDIUM": 1200, "HIGH": 1200}


def bidirectional_penalty(value, low, high, normal_std):
    if low <= value <= high:
        return 0.0
    if value < low:
        return (low - value) / normal_std
    return (value - high) / normal_std


def base_profile(scenario):
    if scenario == "normal":
        age = np.random.normal(27, 5)
        bmi = np.random.normal(24, 3)
        glucose = np.random.normal(90, 12)
        pregnancy_week = np.random.randint(4, 38)
    elif scenario == "borderline":
        age = np.random.normal(31, 6)
        bmi = np.random.normal(28, 4)
        glucose = np.random.normal(103, 18)
        pregnancy_week = np.random.randint(6, 40)
    else:
        age = np.random.normal(34, 7)
        bmi = np.random.normal(31, 5)
        glucose = np.random.normal(118, 28)
        pregnancy_week = np.random.randint(2, 41)
    return age, bmi, glucose, pregnancy_week


def generate_patient():
    scenario = np.random.choice(["normal", "borderline", "extreme"], p=[0.45, 0.35, 0.20])
    age, bmi, glucose, pregnancy_week = base_profile(scenario)

    age = np.clip(age, 16, 47)
    bmi = np.clip(bmi, 15, 46)
    pregnancy_week = int(np.clip(pregnancy_week, 1, 41))

    glucose = glucose + 0.55 * (bmi - 24) + 0.18 * (age - 28) + np.random.normal(0, 6)
    bp_sys = 104 + 0.95 * (age - 25) + 1.05 * (bmi - 23) + 0.30 * (pregnancy_week - 20) + np.random.normal(0, 9)
    bp_dia = 64 + 0.55 * (age - 25) + 0.60 * (bmi - 23) + 0.16 * (pregnancy_week - 20) + np.random.normal(0, 7)
    heart_rate = 79 + 0.22 * (pregnancy_week - 20) + 0.15 * (bmi - 24) + np.random.normal(0, 9)

    if np.random.random() < 0.10:
        glucose -= np.random.uniform(20, 45)
    if np.random.random() < 0.16:
        glucose += np.random.uniform(18, 60)

    if np.random.random() < 0.08:
        bp_sys -= np.random.uniform(14, 28)
        bp_dia -= np.random.uniform(8, 18)
    if np.random.random() < 0.16:
        bp_sys += np.random.uniform(12, 35)
        bp_dia += np.random.uniform(8, 22)

    if np.random.random() < 0.08:
        heart_rate -= np.random.uniform(12, 32)
    if np.random.random() < 0.14:
        heart_rate += np.random.uniform(10, 35)

    glucose = float(np.clip(glucose, 40, 240))
    bp_sys = float(np.clip(bp_sys, 70, 195))
    bp_dia = float(np.clip(bp_dia, 40, 130))
    heart_rate = float(np.clip(heart_rate, 42, 160))

    if bp_dia >= bp_sys - 5:
        bp_dia = bp_sys - np.random.uniform(6, 14)
        bp_dia = float(np.clip(bp_dia, 40, 125))

    risk_score = 0.0
    risk_score += bidirectional_penalty(glucose, 72, 125, 10) * 1.4
    risk_score += bidirectional_penalty(bp_sys, 92, 140, 8) * 1.3
    risk_score += bidirectional_penalty(bp_dia, 58, 90, 6) * 1.1
    risk_score += bidirectional_penalty(heart_rate, 58, 108, 7) * 1.0
    risk_score += bidirectional_penalty(bmi, 18.5, 34, 2.8) * 0.8
    risk_score += bidirectional_penalty(age, 18, 37, 4.5) * 0.5

    if age > 35 and bp_sys > 138:
        risk_score += 2.3
    if bmi > 31 and glucose > 130:
        risk_score += 2.0
    if glucose < 65 and heart_rate < 58:
        risk_score += 2.1
    if bp_sys < 88 and bp_dia < 55:
        risk_score += 1.8
    if pregnancy_week > 33 and (bp_sys > 145 or bp_dia > 95):
        risk_score += 2.2

    risk_percentage = 14 + 8.7 * risk_score + np.random.normal(0, 8)
    risk_percentage = float(np.clip(risk_percentage, 0, 100))

    low_threshold = 31 + np.random.normal(0, 3.4)
    high_threshold = 62 + np.random.normal(0, 3.8)
    if risk_percentage < low_threshold:
        risk_level = "LOW"
    elif risk_percentage < high_threshold:
        risk_level = "MEDIUM"
    else:
        risk_level = "HIGH"

    if np.random.random() < 0.07:
        if risk_level == "LOW":
            risk_level = np.random.choice(["LOW", "MEDIUM"], p=[0.4, 0.6])
        elif risk_level == "HIGH":
            risk_level = np.random.choice(["MEDIUM", "HIGH"], p=[0.6, 0.4])
        else:
            risk_level = np.random.choice(["LOW", "MEDIUM", "HIGH"], p=[0.2, 0.6, 0.2])

    if np.random.random() < 0.30:
        heart_rate_value = np.nan
    else:
        heart_rate_value = round(heart_rate, 2)

    return [
        int(round(age)),
        round(bmi, 2),
        round(glucose, 2),
        round(bp_sys, 2),
        round(bp_dia, 2),
        pregnancy_week,
        heart_rate_value,
        round(risk_percentage, 2),
        risk_level,
    ]


rows = []
counts = {"LOW": 0, "MEDIUM": 0, "HIGH": 0}

while any(counts[level] < TARGET_COUNTS[level] for level in TARGET_COUNTS):
    row = generate_patient()
    level = row[-1]
    if counts[level] < TARGET_COUNTS[level]:
        rows.append(row)
        counts[level] += 1

np.random.shuffle(rows)

df = pd.DataFrame(rows, columns=[
    "age",
    "bmi",
    "glucose",
    "blood_pressure_sys",
    "blood_pressure_dia",
    "pregnancy_week",
    "heart_rate",
    "risk_percentage",
    "risk_level",
])

print("=== Dataset distribution ===")
print(df["risk_level"].value_counts())
print(f"\nTotal rows: {len(df)}")
print(f"\nMissing heart_rate: {df['heart_rate'].isna().sum()} rows ({df['heart_rate'].isna().mean()*100:.1f}%)")
print("\n=== Feature means per risk level ===")
print(df.groupby("risk_level")[["age", "bmi", "glucose", "blood_pressure_sys", "blood_pressure_dia", "heart_rate"]].mean().round(2))

df.to_csv("pregnancy_dataset.csv", index=False)
print("\n✅ pregnancy_dataset.csv saved successfully!")