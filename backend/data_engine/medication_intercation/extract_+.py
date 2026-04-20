import json

with open("interactions_clean.json", "r", encoding="utf-8") as f:
    interactions = json.load(f)

plus_cases = set()
for entry in interactions:
    if "+" in entry["dci_a"]:
        plus_cases.add(entry["dci_a"])
    if "+" in entry["dci_b"]:
        plus_cases.add(entry["dci_b"])

for name in sorted(plus_cases):
    print(name)