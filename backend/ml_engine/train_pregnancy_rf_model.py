import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.metrics import mean_absolute_error, root_mean_squared_error, classification_report
from sklearn.preprocessing import LabelEncoder
import pickle

df = pd.read_csv("c:/sahty/backend/ml_engine/pregnancy_dataset.csv")

heart_rate_median = df["heart_rate"].median()
df["heart_rate"].fillna(heart_rate_median, inplace=True)

le = LabelEncoder()
df["risk_level_encoded"] = le.fit_transform(df["risk_level"])

Features = df.drop(["risk_percentage", "risk_level", "risk_level_encoded"], axis=1)

X_train, X_test, y_reg_train, y_reg_test, y_clf_train, y_clf_test = train_test_split(
    Features,
    df["risk_percentage"],
    df["risk_level_encoded"],
    test_size=0.2,
    random_state=42
)

regressor = RandomForestRegressor(
    n_estimators=200,
    max_depth=12,
    min_samples_split=5,
    random_state=42,
    n_jobs=-1
)
regressor.fit(X_train, y_reg_train)
reg_pred = regressor.predict(X_test)
print("=== Risk Percentage (Regressor) ===")
print("MAE  =", round(mean_absolute_error(y_reg_test, reg_pred), 4))
print("RMSE =", round(root_mean_squared_error(y_reg_test, reg_pred), 4))

classifier = RandomForestClassifier(
    n_estimators=200,
    max_depth=12,
    min_samples_split=5,
    random_state=42,
    class_weight="balanced",
    n_jobs=-1
)
classifier.fit(X_train, y_clf_train)
clf_pred = classifier.predict(X_test)
print("\n=== Risk Level (Classifier) ===")
print(classification_report(y_clf_test, clf_pred, target_names=le.classes_))

with open("pregnancy_rf_regressor.pkl", "wb") as f:
    pickle.dump(regressor, f)

with open("pregnancy_rf_classifier.pkl", "wb") as f:
    pickle.dump(classifier, f)

with open("heart_rate_median.pkl", "wb") as f:
    pickle.dump(heart_rate_median, f)

with open("label_encoder.pkl", "wb") as f:
    pickle.dump(le, f)    

print("\n✅ All models saved!")