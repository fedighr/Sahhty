import pandas as pd
import os

current_folder = os.path.dirname(os.path.abspath(__file__))
old_med_path = os.path.join(current_folder, '../..', 'sources', 'MED_CNAM.csv')
new_med_path = os.path.join(current_folder, '../..', 'sources', 'liste_meds.csv')

old_med = pd.read_csv(old_med_path)
new_med = pd.read_csv(new_med_path)

missing = new_med.merge(old_med, on='NAME_MAIN', how='left', indicator=True)
missing = missing[missing['_merge'] == 'left_only']

missing = missing.drop(columns=['_merge'])

missing.to_csv('new_medications.csv', index=False)

print(f"Found {len(missing)} medications in CSV2 not in CSV1")
print("\nOLD NAME_MAIN samples:")
print(old_med['NAME_MAIN'].head(10).tolist())

print("\nNEW NAME_MAIN samples:")
print(new_med['NAME_MAIN'].head(10).tolist())