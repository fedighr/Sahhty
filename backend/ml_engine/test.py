import os
import pickle
import time
from pathlib import Path

import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC

try:
    from xgboost import XGBClassifier
except ImportError as exc:
    raise ImportError("xgboost is required. Install it with: pip install xgboost") from exc

BASE_DIR = Path(__file__).resolve().parent
ROOT_DIR = BASE_DIR.parent.parent
EXCEL_FILE_PATH = ROOT_DIR / "Paramètres.xlsx"
DATASET_PATH = BASE_DIR / "pregnancy_dataset.csv"
REPORT_PATH = BASE_DIR / "model_comparison_report.pdf"


def load_pickle(path):
    with open(path, "rb") as f:
        return pickle.load(f)


def parse_bp(value):
    bp = float(value)
    if bp <= 30:
        return bp * 10
    return bp


def parse_bmi(row):
    bmi_value = row.get("IMC")
    if not pd.isna(bmi_value):
        return float(bmi_value)

    weight = row.get("Poids (Kg)")
    height = row.get("Taille (m)")
    if pd.isna(weight) or pd.isna(height):
        raise ValueError("Missing BMI and cannot derive it from Poids (Kg) and Taille (m)")

    height = float(height)
    if height <= 0:
        raise ValueError("Invalid height value while deriving BMI")

    return float(weight) / (height * height)


def parse_risk_marker(value):
    if pd.isna(value):
        return 0
    text = str(value).strip()
    if text == "0":
        return 0
    if text == "+":
        return 1
    if text == "++":
        return 2
    return 0


def expected_level_from_excel_row(row):
    score = (
        parse_risk_marker(row["Risque"])
        + parse_risk_marker(row["Risque.1"])
        + parse_risk_marker(row["Risque.2"])
        + parse_risk_marker(row["Risque.3"])
    )
    if score >= 3:
        return "HIGH"
    if score >= 1:
        return "MEDIUM"
    return "LOW"


def load_real_validation_data(heart_rate_median):
    if not EXCEL_FILE_PATH.exists():
        raise FileNotFoundError(f"Excel file not found: {EXCEL_FILE_PATH}")

    df = pd.read_excel(EXCEL_FILE_PATH)
    if str(df.iloc[0, 0]).strip().lower() == "parameter":
        df = df.iloc[1:].reset_index(drop=True)

    features = []
    expected_levels = []

    for _, row in df.iterrows():
        hr_raw = row.get("Fréquence cardiaque")
        if pd.isna(hr_raw):
            hr = float(heart_rate_median)
        else:
            hr = float(hr_raw)

        features.append(
            {
                "age": float(row["Age"]),
                "bmi": parse_bmi(row),
                "glucose": float(row["Glycémie à jeun g/L"]) * 100,
                "blood_pressure_sys": parse_bp(row["TA syst"]),
                "blood_pressure_dia": parse_bp(row["TA diast"]),
                "pregnancy_week": int(row["Semaine d'aménorrhée"]),
                "heart_rate": hr,
            }
        )
        expected_levels.append(expected_level_from_excel_row(row))

    return pd.DataFrame(features), expected_levels


def compute_metrics(y_true_encoded, y_pred_encoded, class_names):
    report = classification_report(
        y_true_encoded,
        y_pred_encoded,
        target_names=class_names,
        output_dict=True,
        zero_division=0,
    )
    return {
        "accuracy": round(float(accuracy_score(y_true_encoded, y_pred_encoded)), 4),
        "f1_per_class": {name: round(float(report[name]["f1-score"]), 4) for name in class_names},
    }


def benchmark_training_times(X_train, y_train, class_names):
    trainers = {
        "Random Forest": RandomForestClassifier(
            n_estimators=250,
            max_depth=13,
            min_samples_split=5,
            random_state=42,
            class_weight="balanced",
            n_jobs=-1,
        ),
        "Logistic Regression": Pipeline(
            [
                ("scaler", StandardScaler()),
                ("clf", LogisticRegression(max_iter=2000, class_weight="balanced", random_state=42)),
            ]
        ),
        "SVM": Pipeline(
            [
                ("scaler", StandardScaler()),
                ("clf", SVC(kernel="rbf", C=2.0, gamma="scale", class_weight="balanced")),
            ]
        ),
        "XGBoost": XGBClassifier(
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
        ),
    }

    training_times = {}
    for model_name, model in trainers.items():
        start = time.perf_counter()
        model.fit(X_train, y_train)
        training_times[model_name] = round(time.perf_counter() - start, 4)
    return training_times


def evaluate_models():
    label_encoder = load_pickle(BASE_DIR / "label_encoder.pkl")
    preprocess_config = load_pickle(BASE_DIR / "preprocess_config.pkl")
    heart_rate_median = load_pickle(BASE_DIR / "heart_rate_median.pkl")
    class_names = list(label_encoder.classes_)
    feature_columns = preprocess_config["feature_columns"]

    models = {
        "Random Forest": load_pickle(BASE_DIR / "pregnancy_rf_classifier.pkl"),
        "Logistic Regression": load_pickle(BASE_DIR / "logistic_classifier.pkl"),
        "SVM": load_pickle(BASE_DIR / "svm_classifier.pkl"),
        "XGBoost": load_pickle(BASE_DIR / "xgboost_classifier.pkl"),
    }

    df = pd.read_csv(DATASET_PATH)
    df["heart_rate"] = df["heart_rate"].fillna(float(heart_rate_median))
    y_all = label_encoder.transform(df["risk_level"])
    X_all = df[feature_columns]

    X_train, X_test, y_train, y_test = train_test_split(
        X_all,
        y_all,
        test_size=0.30,
        random_state=42,
        stratify=y_all,
    )

    X_real, y_real_text = load_real_validation_data(float(heart_rate_median))
    y_real_encoded = label_encoder.transform(y_real_text)

    train_times = benchmark_training_times(X_train, y_train, class_names)

    results = {}
    for model_name, model in models.items():
        pred_test = model.predict(X_test)
        pred_real = model.predict(X_real)

        synthetic_metrics = compute_metrics(y_test, pred_test, class_names)
        real_metrics = compute_metrics(y_real_encoded, pred_real, class_names)

        results[model_name] = {
            "training_time_seconds": train_times[model_name],
            "synthetic": synthetic_metrics,
            "real_excel": real_metrics,
        }

    return results, class_names


def print_results(results, class_names):
    for model_name, payload in results.items():
        print(f"\n=== {model_name} ===")
        print(f"Training time (s): {payload['training_time_seconds']:.4f}")
        print(f"Synthetic accuracy: {payload['synthetic']['accuracy']:.4f}")
        print(f"Synthetic F1 per class: {payload['synthetic']['f1_per_class']}")
        print(f"Real Excel accuracy: {payload['real_excel']['accuracy']:.4f}")
        print(f"Real Excel F1 per class: {payload['real_excel']['f1_per_class']}")


def build_table_rows(results, class_names):
    rows = []
    for model_name, payload in results.items():
        rows.append(
            [
                model_name,
                f"{payload['training_time_seconds']:.3f}",
                f"{payload['synthetic']['accuracy']:.3f}",
                f"{payload['real_excel']['accuracy']:.3f}",
                f"{payload['synthetic']['f1_per_class'][class_names[0]]:.3f}",
                f"{payload['synthetic']['f1_per_class'][class_names[1]]:.3f}",
                f"{payload['synthetic']['f1_per_class'][class_names[2]]:.3f}",
            ]
        )
    return rows


def generate_pdf_report(results, class_names):
    table_headers = ["Model", "Train Time(s)", "Syn Acc", "Real Acc", f"F1 {class_names[0]}", f"F1 {class_names[1]}", f"F1 {class_names[2]}"]
    model_order = sorted(results.keys(), key=lambda m: results[m]["real_excel"]["accuracy"], reverse=True)
    best_model = model_order[0]

    table_rows = []
    for model_name in model_order:
        payload = results[model_name]
        table_rows.append(
            [
                model_name,
                f"{payload['training_time_seconds']:.3f}",
                f"{payload['synthetic']['accuracy']:.3f}",
                f"{payload['real_excel']['accuracy']:.3f}",
                f"{payload['synthetic']['f1_per_class'][class_names[0]]:.3f}",
                f"{payload['synthetic']['f1_per_class'][class_names[1]]:.3f}",
                f"{payload['synthetic']['f1_per_class'][class_names[2]]:.3f}",
            ]
        )

    plt.rcParams.update({"font.size": 10, "axes.titlesize": 12, "axes.labelsize": 10})

    with PdfPages(REPORT_PATH) as pdf:
        fig = plt.figure(figsize=(11.69, 8.27), facecolor="#f7f9fc")
        ax = fig.add_axes([0, 0, 1, 1])
        ax.axis("off")
        ax.add_patch(plt.Rectangle((0.04, 0.84), 0.92, 0.12, color="#1f4e79", transform=ax.transAxes))
        ax.text(0.06, 0.90, "Pregnancy Risk Prediction", color="white", fontsize=24, fontweight="bold", transform=ax.transAxes)
        ax.text(0.06, 0.855, "Model Comparison Report", color="white", fontsize=14, transform=ax.transAxes)

        ax.add_patch(plt.Rectangle((0.06, 0.61), 0.40, 0.18, color="white", transform=ax.transAxes))
        ax.add_patch(plt.Rectangle((0.54, 0.61), 0.40, 0.18, color="white", transform=ax.transAxes))
        ax.text(0.08, 0.75, "Project Scope", fontsize=12, fontweight="bold", color="#1f4e79", transform=ax.transAxes)
        ax.text(0.08, 0.63, "Compare 4 classifiers for\npregnancy risk levels:\nLOW, MEDIUM, HIGH", fontsize=11, transform=ax.transAxes)

        ax.text(0.56, 0.75, "Dataset", fontsize=12, fontweight="bold", color="#1f4e79", transform=ax.transAxes)
        ax.text(0.56, 0.63, "3600 synthetic rows\nBalanced classes\nNoise + overlap + medical interactions", fontsize=11, transform=ax.transAxes)

        ax.text(0.06, 0.50, "Compared Models", fontsize=13, fontweight="bold", color="#1f4e79", transform=ax.transAxes)
        ax.text(0.06, 0.40, "• Random Forest\n• Logistic Regression\n• SVM\n• XGBoost", fontsize=12, transform=ax.transAxes)

        ax.text(0.56, 0.50, "Evaluation", fontsize=13, fontweight="bold", color="#1f4e79", transform=ax.transAxes)
        ax.text(0.56, 0.40, "• Synthetic split: 70/30 (stratified)\n• Real-patient Excel validation\n• Accuracy, F1 per class, training time", fontsize=12, transform=ax.transAxes)

        ax.text(0.06, 0.07, "PFE Student Project — Simple, robust, and interpretable benchmark", fontsize=10, color="#4a4a4a", transform=ax.transAxes)
        pdf.savefig(fig, bbox_inches="tight")
        plt.close(fig)

        fig = plt.figure(figsize=(11.69, 8.27), facecolor="white")
        ax = fig.add_subplot(111)
        ax.axis("off")
        ax.set_title("Side-by-Side Model Comparison", fontsize=16, fontweight="bold", pad=20, color="#1f4e79")
        table = ax.table(cellText=table_rows, colLabels=table_headers, cellLoc="center", loc="center")
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2.0)

        for (row, col), cell in table.get_celld().items():
            if row == 0:
                cell.set_text_props(weight="bold", color="white")
                cell.set_facecolor("#1f4e79")
            elif row % 2 == 0:
                cell.set_facecolor("#eef3f9")
            else:
                cell.set_facecolor("#ffffff")

        best_row_index = 1 + model_order.index(best_model)
        for col in range(len(table_headers)):
            table[(best_row_index, col)].set_facecolor("#d9f2d9")
            if col == 0:
                table[(best_row_index, col)].set_text_props(weight="bold")

        ax.text(0.5, 0.09, f"Best Real Validation Accuracy: {best_model}", ha="center", fontsize=11, color="#2e7d32", fontweight="bold", transform=ax.transAxes)
        pdf.savefig(fig, bbox_inches="tight")
        plt.close(fig)

        syn_acc = [results[m]["synthetic"]["accuracy"] for m in model_order]
        real_acc = [results[m]["real_excel"]["accuracy"] for m in model_order]
        syn_macro_f1 = [sum(results[m]["synthetic"]["f1_per_class"][c] for c in class_names) / len(class_names) for m in model_order]
        real_macro_f1 = [sum(results[m]["real_excel"]["f1_per_class"][c] for c in class_names) / len(class_names) for m in model_order]
        train_times = [results[m]["training_time_seconds"] for m in model_order]

        fig, axes = plt.subplots(2, 2, figsize=(11.69, 8.27), facecolor="white")
        axes[0, 0].bar(model_order, syn_acc, color="#1f77b4")
        axes[0, 0].set_title("Synthetic Accuracy")
        axes[0, 0].set_ylim(0, 1)
        axes[0, 0].tick_params(axis="x", rotation=20)

        axes[0, 1].bar(model_order, real_acc, color="#ff7f0e")
        axes[0, 1].set_title("Real Excel Accuracy")
        axes[0, 1].set_ylim(0, 1)
        axes[0, 1].tick_params(axis="x", rotation=20)

        axes[1, 0].bar(model_order, syn_macro_f1, color="#2ca02c")
        axes[1, 0].set_title("Synthetic Macro F1")
        axes[1, 0].set_ylim(0, 1)
        axes[1, 0].tick_params(axis="x", rotation=20)

        axes[1, 1].bar(model_order, train_times, color="#9467bd")
        axes[1, 1].set_title("Training Time (s)")
        axes[1, 1].tick_params(axis="x", rotation=20)

        fig.suptitle("Performance Charts", fontsize=16, fontweight="bold", color="#1f4e79")
        plt.tight_layout(rect=[0, 0, 1, 0.95])
        pdf.savefig(fig)
        plt.close(fig)

        fig = plt.figure(figsize=(11.69, 8.27), facecolor="#f7f9fc")
        ax = fig.add_axes([0, 0, 1, 1])
        ax.axis("off")
        ax.text(0.06, 0.94, "Model-by-Model Summary", fontsize=18, fontweight="bold", color="#1f4e79", transform=ax.transAxes)

        y = 0.82
        for model_name in model_order:
            payload = results[model_name]
            syn = payload["synthetic"]
            real = payload["real_excel"]
            block = (
                f"{model_name}\n"
                f"Train Time: {payload['training_time_seconds']:.3f}s | Synthetic Acc: {syn['accuracy']:.3f} | Real Acc: {real['accuracy']:.3f}\n"
                f"Synthetic F1 -> {class_names[0]}: {syn['f1_per_class'][class_names[0]]:.3f}, "
                f"{class_names[1]}: {syn['f1_per_class'][class_names[1]]:.3f}, "
                f"{class_names[2]}: {syn['f1_per_class'][class_names[2]]:.3f}\n"
                f"Real F1 -> {class_names[0]}: {real['f1_per_class'][class_names[0]]:.3f}, "
                f"{class_names[1]}: {real['f1_per_class'][class_names[1]]:.3f}, "
                f"{class_names[2]}: {real['f1_per_class'][class_names[2]]:.3f}"
            )
            color = "#e8f5e9" if model_name == best_model else "#ffffff"
            ax.add_patch(plt.Rectangle((0.05, y - 0.09), 0.90, 0.14, color=color, ec="#cbd5e1", transform=ax.transAxes))
            ax.text(0.07, y + 0.03, block, fontsize=10.5, va="top", transform=ax.transAxes)
            y -= 0.19

        pdf.savefig(fig, bbox_inches="tight")
        plt.close(fig)

        fig = plt.figure(figsize=(11.69, 8.27), facecolor="white")
        ax = fig.add_axes([0, 0, 1, 1])
        ax.axis("off")
        conclusion = (
            "Conclusion\n\n"
            f"Best model on real-patient Excel validation: {best_model}.\n\n"
            "Random Forest remains a strong deployment choice in this PFE context because it provides a practical balance:\n"
            "• Strong and stable performance across classes\n"
            "• Simple workflow with little parameter tuning\n"
            "• Robustness to noisy and overlapping medical patterns\n"
            "• Reliable behavior on small and medium datasets\n\n"
            "This makes Random Forest a safe baseline model for student-level clinical risk prototyping."
        )
        ax.add_patch(plt.Rectangle((0.04, 0.80), 0.92, 0.13, color="#1f4e79", transform=ax.transAxes))
        ax.text(0.06, 0.86, "Final Recommendation", color="white", fontsize=18, fontweight="bold", transform=ax.transAxes)
        ax.text(0.06, 0.74, conclusion, fontsize=12, va="top", transform=ax.transAxes)
        pdf.savefig(fig, bbox_inches="tight")
        plt.close(fig)


def main():
    results, class_names = evaluate_models()
    print_results(results, class_names)
    generate_pdf_report(results, class_names)
    print(f"\n✅ PDF report generated: {REPORT_PATH}")


if __name__ == "__main__":
    main()
