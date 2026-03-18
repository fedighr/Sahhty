import os
import pickle
import time

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.svm import SVC

try:
    from xgboost import XGBClassifier
except ImportError as exc:
    raise ImportError(
        "xgboost is required to train xgboost_classifier.pkl. Install it with: pip install xgboost"
    ) from exc

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_PATH = os.path.join(BASE_DIR, "pregnancy_dataset.csv")


def load_data():
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
    y = df["risk_level_encoded"]

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.30,
        random_state=42,
        stratify=y,
    )
    return X_train, X_test, y_train, y_test, label_encoder


def train_and_save(model, model_name, output_file, X_train, X_test, y_train, y_test, class_names):
    start = time.perf_counter()
    model.fit(X_train, y_train)
    elapsed = time.perf_counter() - start

    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, target_names=class_names, output_dict=True, zero_division=0)
    f1_per_class = {name: round(float(report[name]["f1-score"]), 4) for name in class_names}

    with open(os.path.join(BASE_DIR, output_file), "wb") as f:
        pickle.dump(model, f)

    print(f"\n=== {model_name} ===")
    print(f"Training time (s): {elapsed:.4f}")
    print(f"Accuracy: {accuracy:.4f}")
    print(f"F1 per class: {f1_per_class}")


def main():
    X_train, X_test, y_train, y_test, label_encoder = load_data()
    class_names = list(label_encoder.classes_)

    logistic_model = Pipeline(
        [
            ("scaler", StandardScaler()),
            (
                "clf",
                LogisticRegression(
                    max_iter=2000,
                    class_weight="balanced",
                    random_state=42,
                ),
            ),
        ]
    )

    svm_model = Pipeline(
        [
            ("scaler", StandardScaler()),
            ("clf", SVC(kernel="rbf", C=2.0, gamma="scale", class_weight="balanced")),
        ]
    )

    xgb_model = XGBClassifier(
        objective="multi:softmax",
        num_class=len(class_names),
        n_estimators=250,
        max_depth=5,
        learning_rate=0.08,
        subsample=0.9,
        colsample_bytree=0.9,
        reg_lambda=1.0,
        random_state=42,
        n_jobs=-1,
        eval_metric="mlogloss",
    )

    train_and_save(
        logistic_model,
        "Logistic Regression",
        "logistic_classifier.pkl",
        X_train,
        X_test,
        y_train,
        y_test,
        class_names,
    )
    train_and_save(
        svm_model,
        "SVM",
        "svm_classifier.pkl",
        X_train,
        X_test,
        y_train,
        y_test,
        class_names,
    )
    train_and_save(
        xgb_model,
        "XGBoost",
        "xgboost_classifier.pkl",
        X_train,
        X_test,
        y_train,
        y_test,
        class_names,
    )

    print("\n✅ All additional models trained and saved")


if __name__ == "__main__":
    main()
