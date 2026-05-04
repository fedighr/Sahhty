import pandas as pd
import json
import os
import unicodedata
import re

current_folder = os.path.dirname(os.path.abspath(__file__))
interactions = pd.read_csv(os.path.join(current_folder, "interactions_clean.csv"), sep=",")
medications = pd.read_csv(os.path.join(current_folder, "classifications.csv"), sep=",")

def normalize(text):
    if not isinstance(text, str):
        return ""
    # lowercase
    text = text.lower()
    # remove accents
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    # remove extra spaces and special characters
    text = re.sub(r'[^\w\s-]', '', text)
    # collapse multiple spaces
    text = re.sub(r'\s+', ' ', text).strip()
    return text

# Build normalized lookup: normalized_name -> original_name
medication_lookup = {
    normalize(name): name 
    for name in medications["dci_name"].str.strip()
}

def check_dci(dci):
    """Returns (exists, original_name_if_found)"""
    normalized = normalize(dci)
    if normalized in medication_lookup:
        return True, medication_lookup[normalized]
    return False, None

# Process each row
both_exist = []
one_missing = []
two_missing = []

for _, row in interactions.iterrows():
    a_exists, a_matched = check_dci(row["dci_a"])
    b_exists, b_matched = check_dci(row["dci_b"])
    record = row.to_dict()

    if a_exists and b_exists:
        # normalize matched names in valid interactions
        record["dci_a"] = a_matched
        record["dci_b"] = b_matched
        both_exist.append(record)

    elif not a_exists and not b_exists:
        record["missing_dci"] = [row["dci_a"].strip(), row["dci_b"].strip()]
        two_missing.append(record)

    else:
        record["missing_dci"] = row["dci_a"].strip() if not a_exists else row["dci_b"].strip()
        one_missing.append(record)

with open(os.path.join(current_folder, "interactions_valid.json"), "w", encoding="utf-8") as f:
    json.dump(both_exist, f, ensure_ascii=False, indent=2)

with open(os.path.join(current_folder, "interactions_one_missing.json"), "w", encoding="utf-8") as f:
    json.dump(one_missing, f, ensure_ascii=False, indent=2)

with open(os.path.join(current_folder, "interactions_two_missing.json"), "w", encoding="utf-8") as f:
    json.dump(two_missing, f, ensure_ascii=False, indent=2)

print(f"Total interactions:  {len(interactions)}")
print(f"Both DCIs exist:     {len(both_exist)}")
print(f"One DCI missing:     {len(one_missing)}")
print(f"Both DCIs missing:   {len(two_missing)}")