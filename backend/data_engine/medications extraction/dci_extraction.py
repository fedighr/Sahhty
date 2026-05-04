import pandas as pd
import os
import json

current_folder = os.path.dirname(os.path.abspath(__file__))
new_med_path = os.path.join(current_folder, '../..', 'sources', 'new_medications.csv')

plus = open(os.path.join(current_folder, 'extarct_dci_plus.txt'), "w", encoding='utf-8')
moins = open(os.path.join(current_folder, 'extarct_dci_moins.txt'), "w", encoding='utf-8')
slash = open(os.path.join(current_folder, 'extarct_dci_slash.txt'), "w", encoding='utf-8')
deux_points = open(os.path.join(current_folder, 'extarct_dci_deux_points.txt'), "w", encoding='utf-8')
normal = open(os.path.join(current_folder, 'extarct_dci_normal.txt'), "w", encoding='utf-8')
all = open(os.path.join(current_folder, 'extarct_dci_all.txt'), "w", encoding='utf-8')
exception = open(os.path.join(current_folder, 'extarct_dci_exception.txt'), "w", encoding='utf-8')

new_med = pd.read_csv(new_med_path)
dcis = set()
for index, row in new_med.iterrows():
    print(f"Processing medication {index + 1}/{len(new_med)}")
    try:
        dci = row['DCI']
        dcis.add(dci)
        if '+' in dci:
            plus.write(f"{dci}\n")
        elif '-' in dci:
            moins.write(f"{dci}\n")
        elif '/' in dci:
            slash.write(f"{dci}\n")
        elif ':' in dci:
            deux_points.write(f"{dci}\n")
        else:
            normal.write(f"{dci}\n")
    except Exception as e:
        print(f"Error processing medication at index {index}: {e}")
        exception.write(f"Error processing medication at index {index}: {e}\n")

plus.close()
moins.close()
slash.close()
deux_points.close()
normal.close()

for i in sorted(dcis):
    all.write(f"{i}\n")

all.close()

