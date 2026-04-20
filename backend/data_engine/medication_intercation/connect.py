import pandas as pd
import json

interactions = pd.read_csv("interactions_clean.csv", sep=",")
medications = pd.read_csv("dci.csv", sep=",")

medication_names = set(medications["name"].str.strip())

def both_exist(row):
    return row["dci_a"].strip() in medication_names and row["dci_b"].strip() in medication_names

valid = interactions[interactions.apply(both_exist, axis=1)].copy()
invalid = interactions[~interactions.apply(both_exist, axis=1)].copy()

valid.to_json("interactions_valid.json", orient="records", force_ascii=False, indent=2)
invalid.to_json("interactions_invalid.json", orient="records", force_ascii=False, indent=2)

print(f"Total interactions:  {len(interactions)}")
print(f"Both DCIs exist:     {len(valid)}")
print(f"One or both missing: {len(invalid)}")