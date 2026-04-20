#GLUCOCORTICOÏDES (SAUF HYDROCORTISONE)

import json
import re

CLASS_INDICATORS = [
    "MÉDICAMENTS", "SUBSTANCES", "PRODUITS", "INHIBITEURS",
    "INDUCTEURS", "ANTAGONISTES", "AGONISTES", "DIURÉTIQUES",
    "ANTIDÉPRESSEURS", "ANTIBIOTIQUES", "ANTICOAGULANTS",
    "ANTIFONGIQUES", "ANTICANCÉREUX", "BÊTABLOQUANTS",
    "FLUOROPYRIMIDINES", "STATINES",
    "TRIPTANS", "VACCINS", "DÉRIVÉS", "ANALOGUES", "AUTRES", "ALCALOÏDES", "VASOCONSTRICTEURS"
]

def is_drug_class(name):
    words = name.split()
    return len(words) >= 2 and any(k in name for k in CLASS_INDICATORS)

def strip_parentheses(name):
    return re.sub(r'\(.*?\)', '', name).strip()

def clean_interactions(input_path, output_path):
    with open(input_path, "r", encoding="utf-8") as f:
        interactions = json.load(f)

    total = len(interactions)
    cleaned = []
    i = 1

    for interaction in interactions:
        print(f"Processing interaction {i}/{total}")
        i += 1

        if is_drug_class(interaction['dci_a']) or is_drug_class(interaction['dci_b']):
            continue

        interaction['dci_a'] = strip_parentheses(interaction['dci_a'])
        interaction['dci_b'] = strip_parentheses(interaction['dci_b'])

        full_description = f"{interaction['description']} {interaction['recommendation']}".strip()

        cleaned.append({
            "dci_a":       interaction['dci_a'],
            "dci_b":       interaction['dci_b'],
            "severity":    interaction['severity'],
            "description": full_description,
        })

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    print(f"Total:   {total}")
    print(f"Removed: {total - len(cleaned)}")
    print(f"Kept:    {len(cleaned)}")
    print(f"Saved to {output_path}")


clean_interactions("interactions.json", "interactions_clean.json")