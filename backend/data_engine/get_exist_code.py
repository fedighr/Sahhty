import os
import pandas as pd

current_folder = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.join(current_folder, '..', 'sources', 'new_medications.csv')
df = pd.read_csv(file_path)

duplicates = df[df.duplicated(subset=['CODE_PCT'], keep=False)].copy()
duplicates['row_number'] = duplicates.index + 2

with open(os.path.join(current_folder, 'duplicate_codes.txt'), 'w') as f:
    for code, group in duplicates.groupby('CODE_PCT'):
        f.write(f"CODE_PCT: {code} — {len(group)} duplicates\n")
        for _, row in group.iterrows():
            f.write(f"  Row {int(row['row_number'])}: {row.to_dict()}\n")
        f.write("\n")

print(f"Found {duplicates['CODE_PCT'].nunique()} duplicate codes — saved to duplicate_codes.txt")