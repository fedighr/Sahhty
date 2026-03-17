import json
import os
import pickle
from datetime import datetime
import pandas as pd
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.metrics import accuracy_score, classification_report, mean_absolute_error, root_mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_PATH = os.path.join(BASE_DIR, "pregnancy_dataset.csv")


df = pd.read_csv(DATASET_PATH)

heart_rate_median = float(df["heart_rate"].median())
df["heart_rate"] = df["heart_rate"].fillna(heart_rate_median)

label_encoder = LabelEncoder()
df["risk_level_encoded"] = label_encoder.fit_transform(df["risk_level"])

feature_columns = [
    "age",
    "bmi",
    "glucose",
    "blood_pressure_sys",
    "blood_pressure_dia",
    "pregnancy_week",
    "heart_rate",
]

X = df[feature_columns]
y_reg = df["risk_percentage"]
y_clf = df["risk_level_encoded"]

X_train, X_test, y_reg_train, y_reg_test, y_clf_train, y_clf_test = train_test_split(
    X,
    y_reg,
    y_clf,
    test_size=0.30,
    random_state=42,
    stratify=y_clf,
)

regressor = RandomForestRegressor(
    n_estimators=250,
    max_depth=13,
    min_samples_split=5,
    random_state=42,
    n_jobs=-1,
)
regressor.fit(X_train, y_reg_train)
reg_pred = regressor.predict(X_test)

classifier = RandomForestClassifier(
    n_estimators=250,
    max_depth=13,
    min_samples_split=5,
    random_state=42,
    class_weight="balanced",
    n_jobs=-1,
)
classifier.fit(X_train, y_clf_train)
clf_pred = classifier.predict(X_test)

class_names = list(label_encoder.classes_)
report = classification_report(y_clf_test, clf_pred, target_names=class_names, output_dict=True)

per_class_accuracy = {name: round(float(report[name]["recall"]), 4) for name in class_names}

metrics = {
    "trained_at": datetime.utcnow().isoformat() + "Z",
    "split": {"train": 0.70, "test": 0.30, "random_state": 42, "stratified": True},
    "dataset_rows": int(len(df)),
    "class_distribution": {k: int(v) for k, v in df["risk_level"].value_counts().to_dict().items()},
    "regression": {
        "mae": round(float(mean_absolute_error(y_reg_test, reg_pred)), 4),
        "rmse": round(float(root_mean_squared_error(y_reg_test, reg_pred)), 4),
    },
    "classification": {
        "accuracy": round(float(accuracy_score(y_clf_test, clf_pred)), 4),
        "f1_per_class": {name: round(float(report[name]["f1-score"]), 4) for name in class_names},
        "accuracy_per_class": per_class_accuracy,
    },
}

preprocess_config = {
    "heart_rate_median": heart_rate_median,
    "feature_columns": feature_columns,
}

with open(os.path.join(BASE_DIR, "pregnancy_rf_classifier.pkl"), "wb") as f:
    pickle.dump(classifier, f)
with open(os.path.join(BASE_DIR, "pregnancy_rf_regressor.pkl"), "wb") as f:
    pickle.dump(regressor, f)
with open(os.path.join(BASE_DIR, "label_encoder.pkl"), "wb") as f:
    pickle.dump(label_encoder, f)
with open(os.path.join(BASE_DIR, "heart_rate_median.pkl"), "wb") as f:
    pickle.dump(heart_rate_median, f)
with open(os.path.join(BASE_DIR, "preprocess_config.pkl"), "wb") as f:
    pickle.dump(preprocess_config, f)

with open(os.path.join(BASE_DIR, "metrics.json"), "w", encoding="utf-8") as f:
    json.dump(metrics, f, indent=2)

print("=== Risk Percentage (Regressor) ===")
print("MAE  =", metrics["regression"]["mae"])
print("RMSE =", metrics["regression"]["rmse"])
print("\n=== Risk Level (Classifier) ===")
print("F1 per class:", metrics["classification"]["f1_per_class"])
print("Accuracy per class:", metrics["classification"]["accuracy_per_class"])
print("\n✅ Models and metrics saved")