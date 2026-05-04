import os
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def classify_dci(dci):
    if pd.isna(dci) or not str(dci).strip():
        return 'MISSING'
    
    dci_upper = dci.upper()
    
    if any(x in dci_upper for x in ['VACCINE', 'VACCIN', 'ARNM', 'SARS', 'MRNA', 'SPIKE']):
        return 'VACCINE'
    
    if any(x in dci_upper for x in ['INTERFERON', 'IMMUNOGLOBULINE', 'FACTEUR DE COAGULATION']):
        return 'BIOLOGICAL'
    
    if any(x in dci_upper for x in ['SPORES', 'BACILLUS']):
        return 'PROBIOTIC'
    
    if 'OLIGO' in dci_upper:
        return 'SUPPLEMENT'
    
    if dci_upper.endswith(('TE', 'UR', 'AU')):
        return 'TRUNCATED'
    
    if ' - ' in dci:
        return 'COMBINATION'
    
    return 'STANDARD'


input_file = os.path.join(BASE_DIR, "extarct_dci_moins.txt")
output_file = os.path.join(BASE_DIR, "classified_dci.txt")
issues_file = os.path.join(BASE_DIR, "issues.txt")

results = []
issues = []

with open(input_file, "r", encoding="utf-8") as f:
    for line in f:
        dci = line.strip()
        if not dci:
            continue
        
        dci_type = classify_dci(dci)
        cleaned_dci = dci.replace(' - ', ' + ')
        
        results.append(f"{cleaned_dci} | {dci_type}")
        
        if dci_type in ['MISSING', 'TRUNCATED', 'SUPPLEMENT']:
            issues.append(f"{cleaned_dci} | {dci_type}")

with open(output_file, "w", encoding="utf-8") as f:
    for line in results:
        f.write(line + "\n")

with open(issues_file, "w", encoding="utf-8") as f:
    for line in issues:
        f.write(line + "\n")

print(f"Saved {len(results)} entries to {output_file}")
print(f"Found {len(issues)} issues (saved in {issues_file})")