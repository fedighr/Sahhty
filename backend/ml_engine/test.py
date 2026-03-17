import os
from pathlib import Path

import pandas as pd
from docx import Document

from predictor import predict_risk

BASE_DIR = Path(__file__).resolve().parent
ROOT_DIR = BASE_DIR.parent.parent
EXCEL_PATH = ROOT_DIR / "Paramètres.xlsx"
DOCX_PATH = ROOT_DIR / "Valeurs normales femme enceinte.docx"


def parse_bp(value):
    return float(value) * 10


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
        parse_risk_marker(row["Risque"]) +
        parse_risk_marker(row["Risque.1"]) +
        parse_risk_marker(row["Risque.2"]) +
        parse_risk_marker(row["Risque.3"])
    )
    if score >= 3:
        return "HIGH"
    if score >= 1:
        return "MEDIUM"
    return "LOW"


def test_from_excel():
    if not EXCEL_PATH.exists():
        raise FileNotFoundError(f"Excel file not found: {EXCEL_PATH}")

    df = pd.read_excel(EXCEL_PATH)
    if str(df.iloc[0, 0]).strip().lower() == "parameter":
        df = df.iloc[1:].reset_index(drop=True)

    results = []
    for _, row in df.iterrows():
        data = {
            "age": float(row["Age"]),
            "bmi": float(row["IMC"]),
            "glucose": float(row["Glycémie à jeun g/L"]) * 100,
            "blood_pressure_sys": parse_bp(row["TA syst"]),
            "blood_pressure_dia": parse_bp(row["TA diast"]),
            "pregnancy_week": int(row["Semaine d'aménorrhée"]),
            "heart_rate": float(row["Fréquence cardiaque"]),
        }
        expected = expected_level_from_excel_row(row)
        predicted_level, predicted_pct, _ = predict_risk(data)
        match = predicted_level == expected
        results.append((expected, predicted_level, predicted_pct, match, data))

    total = len(results)
    correct = sum(1 for r in results if r[3])
    print("=== Excel-based tests ===")
    print(f"Matched labels: {correct}/{total} ({(100 * correct / total):.1f}%)")
    for expected, predicted, pct, match, data in results:
        status = "✅" if match else "❌"
        print(
            f"{status} expected={expected:<6} predicted={predicted:<6} pct={pct:>5.2f}% "
            f"age={data['age']:.0f} week={data['pregnancy_week']} glucose={data['glucose']:.0f}"
        )


def extract_normal_values_from_doc():
    if not DOCX_PATH.exists():
        raise FileNotFoundError(f"Word file not found: {DOCX_PATH}")
    doc = Document(DOCX_PATH)
    text = "\n".join(p.text for p in doc.paragraphs if p.text.strip())

    hr_low, hr_high = 60.0, 100.0
    bp_sys, bp_dia = 120.0, 80.0
    glucose = 92.0

    return {
        "text": text,
        "heart_rate_low": hr_low,
        "heart_rate_high": hr_high,
        "bp_sys_normal": bp_sys,
        "bp_dia_normal": bp_dia,
        "glucose_normal": glucose,
    }


def test_from_word_normals():
    normal = extract_normal_values_from_doc()

    cases = [
        ("normal_reference", "LOW", {
            "age": 28,
            "bmi": 24.0,
            "glucose": normal["glucose_normal"],
            "blood_pressure_sys": normal["bp_sys_normal"],
            "blood_pressure_dia": normal["bp_dia_normal"],
            "pregnancy_week": 24,
            "heart_rate": 80,
        }),
        ("danger_high_bp", "HIGH", {
            "age": 34,
            "bmi": 28.0,
            "glucose": 110,
            "blood_pressure_sys": 145,
            "blood_pressure_dia": 95,
            "pregnancy_week": 30,
            "heart_rate": 96,
        }),
        ("abnormal_low_glucose", "MEDIUM", {
            "age": 25,
            "bmi": 22.0,
            "glucose": 55,
            "blood_pressure_sys": 108,
            "blood_pressure_dia": 68,
            "pregnancy_week": 16,
            "heart_rate": 72,
        }),
        ("abnormal_low_bp", "MEDIUM", {
            "age": 27,
            "bmi": 23.0,
            "glucose": 90,
            "blood_pressure_sys": 82,
            "blood_pressure_dia": 50,
            "pregnancy_week": 18,
            "heart_rate": 74,
        }),
        ("abnormal_low_hr", "MEDIUM", {
            "age": 26,
            "bmi": 23.5,
            "glucose": 89,
            "blood_pressure_sys": 110,
            "blood_pressure_dia": 70,
            "pregnancy_week": 22,
            "heart_rate": 48,
        }),
    ]

    print("\n=== Word-based normal/abnormal tests ===")
    print(normal["text"])
    matched = 0
    for name, expected, data in cases:
        predicted_level, predicted_pct, _ = predict_risk(data)
        ok = predicted_level == expected
        if ok:
            matched += 1
        status = "✅" if ok else "❌"
        print(f"{status} {name:<20} expected={expected:<6} predicted={predicted_level:<6} pct={predicted_pct:>5.2f}%")

    missing_week_case = {
        "age": 29,
        "bmi": 24.5,
        "glucose": 92,
        "blood_pressure_sys": 118,
        "blood_pressure_dia": 77,
        "heart_rate": 82,
    }
    try:
        predict_risk(missing_week_case)
        print("❌ missing_week_validation expected=ValueError predicted=no_error")
    except ValueError as exc:
        print(f"✅ missing_week_validation expected=ValueError predicted=ValueError message={exc}")

    print(f"Matched labels: {matched}/{len(cases)} ({(100 * matched / len(cases)):.1f}%)")


if __name__ == "__main__":
    os.chdir(BASE_DIR)
    test_from_excel()
    test_from_word_normals()
