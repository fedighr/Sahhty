import pickle
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.svm import SVC

try:
    from xgboost import XGBClassifier
    HAS_XGBOOST = True
except ImportError:
    HAS_XGBOOST = False


BASE_DIR = Path(__file__).resolve().parent
SOURCES_DIR = BASE_DIR.parent / "sources"
DATASET_PATH = SOURCES_DIR / "Maternal Health Risk Data Set.csv"
MODEL_PATH = BASE_DIR / "best_model.pkl"
ENCODER_PATH = BASE_DIR / "label_encoder.pkl"


def load_dataset(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Dataset not found: {path}")

    df = pd.read_csv(path)
    df.columns = [c.strip() for c in df.columns]

    required = ["Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate", "RiskLevel"]
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    df["RiskLevel"] = df["RiskLevel"].astype(str).str.strip().str.lower()
    label_map = {
        "low risk": "LOW",
        "mid risk": "MEDIUM",
        "medium risk": "MEDIUM",
        "high risk": "HIGH",
    }
    df["RiskLevel"] = df["RiskLevel"].map(label_map)

    if df["RiskLevel"].isna().any():
        bad = df[df["RiskLevel"].isna()]
        raise ValueError(f"Unmapped RiskLevel values found:\n{bad.head()}")

    numeric_cols = ["Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate"]
    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df = df.dropna().reset_index(drop=True)
    return df


def add_features(df: pd.DataFrame) -> pd.DataFrame:
    x = df.copy()

    x["PulsePressure"] = x["SystolicBP"] - x["DiastolicBP"]
    x["BP_Ratio"] = x["SystolicBP"] / (x["DiastolicBP"] + 1e-6)
    x["MAP"] = (2 * x["DiastolicBP"] + x["SystolicBP"]) / 3
    x["ShockIndex"] = x["HeartRate"] / (x["SystolicBP"] + 1e-6)
    x["TempHigh"] = (x["BodyTemp"] >= 101).astype(int)
    x["BS_High"] = (x["BS"] >= 8.0).astype(int)
    x["HR_BP_Ratio"] = x["HeartRate"] / (x["DiastolicBP"] + 1e-6)
    x["BS_Temp"] = x["BS"] * x["BodyTemp"]
    x["BP_Age"] = x["SystolicBP"] * x["Age"]

    # age groups
    x["AgeGroup"] = pd.cut(
        x["Age"],
        bins=[0, 20, 30, 40, 50, 60, 100],
        labels=False,
        include_lowest=True
    )
    x["AgeGroup"] = x["AgeGroup"].fillna(0).astype(int)

    return x


def build_models(num_classes: int) -> dict:
    models = {
        "Random Forest": RandomForestClassifier(
            n_estimators=400,
            max_depth=14,
            min_samples_split=4,
            min_samples_leaf=2,
            class_weight="balanced",
            random_state=42,
            n_jobs=-1,
        ),
        "Logistic Regression": Pipeline(
            [
                ("scaler", StandardScaler()),
                ("clf", LogisticRegression(
                    max_iter=4000,
                    class_weight="balanced",
                    random_state=42,
                    multi_class="auto",
                )),
            ]
        ),
        "SVM": Pipeline(
            [
                ("scaler", StandardScaler()),
                ("clf", SVC(
                    kernel="rbf",
                    C=3.0,
                    gamma="scale",
                    class_weight="balanced",
                    probability=True,
                    random_state=42,
                )),
            ]
        ),
    }

    if HAS_XGBOOST:
        models["XGBoost"] = XGBClassifier(
            objective="multi:softprob",
            num_class=num_classes,
            n_estimators=600,
            max_depth=5,
            learning_rate=0.05,
            subsample=1.0,
            colsample_bytree=0.7,
            min_child_weight=1,
            gamma=0,
            reg_alpha=0.1,
            reg_lambda=2,
            random_state=42,
            n_jobs=-1,
            eval_metric="mlogloss",
        )

    return models


def get_prediction_confidence(model, X):
    if hasattr(model, "predict_proba"):
        probs = model.predict_proba(X)
        conf = probs.max(axis=1) * 100
        return pd.Series(conf.round(2))

    if hasattr(model, "decision_function"):
        scores = model.decision_function(X)

        if scores.ndim == 1:
            scores = np.vstack([-scores, scores]).T

        exp_scores = np.exp(scores - scores.max(axis=1, keepdims=True))
        probs = exp_scores / exp_scores.sum(axis=1, keepdims=True)
        conf = probs.max(axis=1) * 100
        return pd.Series(conf.round(2))

    return pd.Series([0.0] * len(X))


def evaluate_model(model, X_train, X_test, y_train, y_test, class_names):
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    confidence = get_prediction_confidence(model, X_test)

    accuracy = accuracy_score(y_test, y_pred)
    macro_f1 = f1_score(y_test, y_pred, average="macro")
    weighted_f1 = f1_score(y_test, y_pred, average="weighted")
    matched = int((y_test == y_pred).sum())
    total = int(len(y_test))
    match_pct = (matched / total) * 100 if total else 0

    report_text = classification_report(
        y_test,
        y_pred,
        target_names=class_names,
        zero_division=0,
    )

    report_dict = classification_report(
        y_test,
        y_pred,
        target_names=class_names,
        output_dict=True,
        zero_division=0,
    )

    f1_per_class = {
        class_name: round(float(report_dict[class_name]["f1-score"]), 4)
        for class_name in class_names
    }

    cm = confusion_matrix(y_test, y_pred)

    return {
        "model": model,
        "accuracy": round(float(accuracy), 4),
        "macro_f1": round(float(macro_f1), 4),
        "weighted_f1": round(float(weighted_f1), 4),
        "f1_per_class": f1_per_class,
        "classification_report_text": report_text,
        "confusion_matrix": cm,
        "y_pred": y_pred,
        "confidence": confidence,
        "matched": matched,
        "total": total,
        "match_pct": round(match_pct, 1),
    }


def print_summary(results):
    print("\n" + "=" * 80)
    print("MODEL SUMMARY")
    print("=" * 80)

    for model_name, payload in results.items():
        print(f"\n=== {model_name} ===")
        print(f"Accuracy: {payload['accuracy']:.4f}")
        print(f"Macro F1: {payload['macro_f1']:.4f}")
        print(f"Weighted F1: {payload['weighted_f1']:.4f}")
        print(f"F1 per class: {payload['f1_per_class']}")
        print("\nClassification Report:")
        print(payload["classification_report_text"])
        print("Confusion Matrix:")
        print(payload["confusion_matrix"])


def print_case_by_case_results(model_name, X_test_display, y_true, y_pred, confidence, label_encoder):
    y_true_text = label_encoder.inverse_transform(y_true)
    y_pred_text = label_encoder.inverse_transform(y_pred)

    matched = int((y_true == y_pred).sum())
    total = len(y_true)
    match_pct = (matched / total) * 100 if total else 0

    print("\n" + "=" * 80)
    print(f"{model_name} - CASE BY CASE RESULTS")
    print("=" * 80)
    print(f"Matched labels: {matched}/{total} ({match_pct:.1f}%)\n")

    for i in range(total):
        ok = y_true[i] == y_pred[i]
        mark = "V" if ok else "F"

        row = X_test_display.iloc[i]

        print(
            f"{mark} "
            f"expected={y_true_text[i]:<8} "
            f"predicted={y_pred_text[i]:<8} "
            f"pct={confidence.iloc[i]:>6.2f}% "
            f"age={row['Age']} "
            f"sys={row['SystolicBP']} "
            f"dia={row['DiastolicBP']} "
            f"bs={row['BS']} "
            f"temp={row['BodyTemp']} "
            f"hr={row['HeartRate']}"
        )


def final_summary(results, class_names):
    print("\n" + "=" * 80)
    print("FINAL SUMMARY TABLE")
    print("=" * 80)

    rows = []
    for model_name, payload in results.items():
        rows.append({
            "Model": model_name,
            "Matched": f"{payload['matched']}/{payload['total']}",
            "Match %": payload["match_pct"],
            "Accuracy": payload["accuracy"],
            "Macro F1": payload["macro_f1"],
            "Weighted F1": payload["weighted_f1"],
            f"F1 {class_names[0]}": payload["f1_per_class"][class_names[0]],
            f"F1 {class_names[1]}": payload["f1_per_class"][class_names[1]],
            f"F1 {class_names[2]}": payload["f1_per_class"][class_names[2]],
        })

    df_summary = pd.DataFrame(rows)
    df_summary = df_summary.sort_values(
        by=["Accuracy", "Macro F1"],
        ascending=False
    ).reset_index(drop=True)

    print(df_summary.to_string(index=False))

    best_model_name = df_summary.iloc[0]["Model"]

    print("\n" + "=" * 80)
    print("RESUME / CONCLUSION")
    print("=" * 80)
    print(f"Best model based on Accuracy: {best_model_name}")
    print("\nDetails:")
    print(df_summary.iloc[0])

    models = df_summary["Model"]
    acc = df_summary["Accuracy"]
    f1 = df_summary["Macro F1"]

    plt.figure(figsize=(10, 6))
    plt.bar(models, acc)
    plt.title("Model Accuracy Comparison")
    plt.xlabel("Models")
    plt.ylabel("Accuracy")
    plt.xticks(rotation=20)
    plt.tight_layout()
    plt.show()

    plt.figure(figsize=(10, 6))
    plt.bar(models, f1)
    plt.title("Model Macro F1 Comparison")
    plt.xlabel("Models")
    plt.ylabel("Macro F1")
    plt.xticks(rotation=20)
    plt.tight_layout()
    plt.show()

    return best_model_name, df_summary


def save_best_model(best_model, label_encoder):
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(best_model, f)

    with open(ENCODER_PATH, "wb") as f:
        pickle.dump(label_encoder, f)

    print("\nSaved:")
    print(f"- Best model -> {MODEL_PATH}")
    print(f"- Label encoder -> {ENCODER_PATH}")


def predict_new_patient(models, label_encoder):
    print("\n" + "=" * 80)
    print("NEW PATIENT PREDICTION")
    print("=" * 80)

    new_data_raw = pd.DataFrame([{
        "Age": 28,
        "SystolicBP": 120,
        "DiastolicBP": 80,
        "BS": 7.2,
        "BodyTemp": 98.0,
        "HeartRate": 78,
    }])

    new_data = add_features(new_data_raw)

    print("\nInput row:")
    print(new_data_raw.to_string(index=False))

    for model_name, model in models.items():
        pred_encoded = model.predict(new_data)[0]
        pred_label = label_encoder.inverse_transform([pred_encoded])[0]

        if hasattr(model, "predict_proba"):
            probs = model.predict_proba(new_data)[0]
            confidence = float(probs.max()) * 100
        else:
            confidence = 0.0

        print(f"{model_name}: predicted risk = {pred_label}, confidence = {confidence:.2f}%")


def main():
    df = load_dataset(DATASET_PATH)

    base_feature_columns = ["Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate"]
    target_column = "RiskLevel"

    X_base = df[base_feature_columns].copy()
    X = add_features(X_base)
    y_text = df[target_column]

    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(y_text)
    class_names = list(label_encoder.classes_)

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.30,
        random_state=42,
        stratify=y,
    )

    X_test_display = X_test[base_feature_columns].reset_index(drop=True)
    y_test_reset = pd.Series(y_test).reset_index(drop=True)

    models = build_models(num_classes=len(class_names))

    results = {}
    for model_name, model in models.items():
        payload = evaluate_model(
            model=model,
            X_train=X_train,
            X_test=X_test,
            y_train=y_train,
            y_test=y_test,
            class_names=class_names,
        )
        results[model_name] = payload

    print_summary(results)

    for model_name, payload in results.items():
        y_pred_reset = pd.Series(payload["y_pred"]).reset_index(drop=True)
        conf_reset = pd.Series(payload["confidence"]).reset_index(drop=True)

        print_case_by_case_results(
            model_name=model_name,
            X_test_display=X_test_display,
            y_true=y_test_reset.to_numpy(),
            y_pred=y_pred_reset.to_numpy(),
            confidence=conf_reset,
            label_encoder=label_encoder,
        )

    best_name = max(
        results,
        key=lambda name: (results[name]["accuracy"], results[name]["macro_f1"])
    )

    print("\n" + "=" * 80)
    print(f"BEST MODEL: {best_name}")
    print("=" * 80)
    print(results[best_name])

    best_model_name, _ = final_summary(results, class_names)
    save_best_model(results[best_model_name]["model"], label_encoder)
    predict_new_patient(
        {name: payload["model"] for name, payload in results.items()},
        label_encoder
    )


if __name__ == "__main__":
    main()