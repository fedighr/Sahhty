import os

folder_path = os.path.dirname(os.path.abspath(__file__))
input_file = os.path.join(folder_path, "clean_dci.txt")
input_dcis = os.path.join(folder_path, "DCI_dataset.txt")
output_file = os.path.join(folder_path, "unique_dci.txt")

with open(input_file, "r", encoding="utf-8") as f:
    dci_set = set(line.strip() for line in f if line.strip())
with open(input_dcis, "r", encoding="utf-8") as f:
    dataset_dcis = set(line.strip() for line in f if line.strip())
unique_dcis = dci_set - dataset_dcis
with open(output_file, "w", encoding="utf-8") as f:
    for dci in sorted(unique_dcis):
        f.write(dci + "\n")