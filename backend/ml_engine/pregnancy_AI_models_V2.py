import pickle
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, f1_score
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
DATASET_PATH = BASE_DIR / "pregnancy_dataset.csv"


def load_dataset(path: Path):
    if not path.exists():
        raise FileNotFoundError(f"Dataset not found: {path}")

    df = pd.read_csv(path)
    df.columns = [c.strip() for c in df.columns]

    required = [
        "age",
        "bmi",
        "glucose",
        "blood_pressure_sys",
        "blood_pressure_dia",
        "pregnancy_week",
        "heart_rate",
        "risk_level",
    ]
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    heart_rate_median = float(df["heart_rate"].median())
    df["heart_rate"] = df["heart_rate"].fillna(heart_rate_median)

    df["risk_level"] = df["risk_level"].astype(str).str.strip().str.lower()
    label_map = {
        "low": "LOW",
        "low risk": "LOW",
        "medium": "MEDIUM",
        "mid risk": "MEDIUM",
        "medium risk": "MEDIUM",
        "high": "HIGH",
        "high risk": "HIGH",
    }
    df["risk_level"] = df["risk_level"].map(label_map)

    if df["risk_level"].isna().any():
        bad = df[df["risk_level"].isna()]
        raise ValueError(f"Unmapped risk_level values found:\n{bad.head()}")

    numeric_cols = [
        "age",
        "bmi",
        "glucose",
        "blood_pressure_sys",
        "blood_pressure_dia",
        "pregnancy_week",
        "heart_rate",
    ]
    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    df = df.dropna().reset_index(drop=True)
    return df, heart_rate_median


def build_models(num_classes: int) -> dict:
    models = {
        "Random Forest": RandomForestClassifier(
            n_estimators=300,
            max_depth=12,
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
                    max_iter=3000,
                    class_weight="balanced",
                    random_state=42,
                )),
            ]
        ),
        "SVM": Pipeline(
            [
                ("scaler", StandardScaler()),
                ("clf", SVC(
                    kernel="rbf",
                    C=2.0,
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
            n_estimators=300,
            max_depth=5,
            learning_rate=0.08,
            subsample=0.9,
            colsample_bytree=0.9,
            reg_lambda=1.0,
            random_state=42,
            n_jobs=-1,
            eval_metric="mlogloss",
        )

    return models


def get_prediction_confidence(model, X):
    if hasattr(model, "predict_proba"):
        probs = model.predict_proba(X)
        conf = probs.max(axis=1) * 100
        return conf.round(2)

    if hasattr(model, "decision_function"):
        import numpy as np

        scores = model.decision_function(X)

        if scores.ndim == 1:
            scores = np.vstack([-scores, scores]).T

        exp_scores = np.exp(scores - scores.max(axis=1, keepdims=True))
        probs = exp_scores / exp_scores.sum(axis=1, keepdims=True)
        conf = probs.max(axis=1) * 100
        return conf.round(2)

    return pd.Series([0.0] * len(X))


def evaluate_model(model, X_train, X_test, y_train, y_test, class_names):
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    confidence = get_prediction_confidence(model, X_test)

    accuracy = accuracy_score(y_test, y_pred)
    macro_f1 = f1_score(y_test, y_pred, average="macro")
    weighted_f1 = f1_score(y_test, y_pred, average="weighted")
    matched = (y_test == y_pred).sum()
    total = len(y_test)
    match_pct = (matched / total) * 100 if total else 0
    report = classification_report(
        y_test,
        y_pred,
        target_names=class_names,
        output_dict=True,
        zero_division=0,
    )

    f1_per_class = {
        class_name: round(float(report[class_name]["f1-score"]), 4)
        for class_name in class_names
    }

    return {
        "model": model,
        "accuracy": round(float(accuracy), 4),
        "macro_f1": round(float(macro_f1), 4),
        "weighted_f1": round(float(weighted_f1), 4),
        "f1_per_class": f1_per_class,
        "y_pred": y_pred,
        "confidence": confidence,
        "matched": int(matched),
        "total": int(total),
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


def print_case_by_case_results(model_name, X_test_display, y_true, y_pred, confidence, label_encoder):
    y_true_text = label_encoder.inverse_transform(y_true)
    y_pred_text = label_encoder.inverse_transform(y_pred)

    matched = (y_true == y_pred).sum()
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

        age = row["age"]
        bmi = row["bmi"]
        glucose = row["glucose"]
        sys_bp = row["blood_pressure_sys"]
        dia_bp = row["blood_pressure_dia"]
        week = row["pregnancy_week"]
        hr = row["heart_rate"]

        print(
            f"{mark} "
            f"expected={y_true_text[i]:<6} "
            f"predicted={y_pred_text[i]:<6} "
            f"pct={confidence[i]:>6.2f}% "
            f"age={age} "
            f"bmi={bmi} "
            f"glucose={glucose} "
            f"sys={sys_bp} "
            f"dia={dia_bp} "
            f"week={week} "
            f"hr={hr}"
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

    df = pd.DataFrame(rows)
    df = df.sort_values(by="Accuracy", ascending=False).reset_index(drop=True)

    print(df.to_string(index=False))

    best_model = df.iloc[0]["Model"]

    print("\n" + "=" * 80)
    print("RESUME / CONCLUSION")
    print("=" * 80)
    best_model = df.iloc[0]["Model"]
    print(f"Best model based on Accuracy: {best_model}")

    print("\nDetails:")
    best_row = df.iloc[0]
    print(best_row)

    models = df["Model"]
    acc = df["Accuracy"]
    f1 = df["Macro F1"]

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


def save_v2_artifacts(models, label_encoder, heart_rate_median, feature_columns):
    filename_map = {
        "Random Forest": "pregnancy_rf_classifier_V2.pkl",
        "Logistic Regression": "logistic_classifier_V2.pkl",
        "SVM": "svm_classifier_V2.pkl",
        "XGBoost": "xgboost_classifier_V2.pkl",
    }

    for model_name, model in models.items():
        target_name = filename_map.get(model_name)
        if target_name is not None:
            with open(BASE_DIR / target_name, "wb") as f:
                pickle.dump(model, f)

    with open(BASE_DIR / "label_encoder_V2.pkl", "wb") as f:
        pickle.dump(label_encoder, f)

    preprocess_config = {
        "heart_rate_median": float(heart_rate_median),
        "feature_columns": feature_columns,
    }
    with open(BASE_DIR / "preprocess_config_V2.pkl", "wb") as f:
        pickle.dump(preprocess_config, f)

    with open(BASE_DIR / "heart_rate_median_V2.pkl", "wb") as f:
        pickle.dump(float(heart_rate_median), f)


def predict_new_patient(models, label_encoder):
    print("\n" + "=" * 80)
    print("NEW PATIENT PREDICTION")
    print("=" * 80)

    new_data = pd.DataFrame([{
        "age": 28,
        "bmi": 24.5,
        "glucose": 92,
        "blood_pressure_sys": 120,
        "blood_pressure_dia": 80,
        "pregnancy_week": 20,
        "heart_rate": 78,
    }])

    print("\nInput row:")
    print(new_data.to_string(index=False))

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
    df, heart_rate_median = load_dataset(DATASET_PATH)

    feature_columns = ["age", "bmi", "glucose", "blood_pressure_sys", "blood_pressure_dia", "pregnancy_week", "heart_rate"]
    target_column = "risk_level"

    X = df[feature_columns]
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

    X_test_display = X_test.reset_index(drop=True)
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
            confidence=conf_reset.to_numpy(),
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

    save_v2_artifacts(models, label_encoder, heart_rate_median, feature_columns)
    final_summary(results, class_names)
    predict_new_patient(models, label_encoder)


if __name__ == "__main__":
    main()
