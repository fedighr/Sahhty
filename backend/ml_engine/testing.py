from pathlib import Path
import pickle
import pandas as pd

# =====================
# PATHS
# =====================

BASE_DIR = Path(__file__).resolve().parent
SOURCES_DIR = BASE_DIR.parent / "sources"


# =====================
# LOAD MODEL
# =====================
with open("best_model.pkl", "rb") as f:
    model = pickle.load(f)

with open("label_encoder.pkl", "rb") as f:
    encoder = pickle.load(f)


# =====================
# FEATURE ENGINEERING
# =====================
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


# =====================
# LOAD DATA
# =====================
df = pd.read_csv(SOURCES_DIR / "test_with_truth.csv")

# normalize labels
df["RiskLevel"] = df["RiskLevel"].str.strip().str.lower()
map_labels = {
    "low risk": "LOW",
    "mid risk": "MEDIUM",
    "high risk": "HIGH"
}
df["RiskLevel"] = df["RiskLevel"].map(map_labels)

# =====================
# PREPARE INPUT
# =====================
required = ["Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate"]

X = df[required].copy()
X = add_features(X)

# =====================
# PREDICT
# =====================
pred = model.predict(X)
pred_labels = encoder.inverse_transform(pred)

df["Predicted"] = pred_labels

# =====================
# COMPARE
# =====================
df["Correct"] = df["RiskLevel"] == df["Predicted"]

accuracy = df["Correct"].mean() * 100

print("\n" + "="*80)
print("RESULTS")
print("="*80)

print(df[[
    "Age","SystolicBP","DiastolicBP","BS",
    "RiskLevel","Predicted","Correct"
]])

print("\nAccuracy:", round(accuracy, 2), "%")

# save
df.to_csv(SOURCES_DIR / "comparison_output.csv", index=False)
print("\nSaved -> ", SOURCES_DIR / "comparison_output.csv")