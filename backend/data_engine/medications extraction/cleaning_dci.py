import os


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
dci_path = os.path.join(BASE_DIR, "extarct_dci_all.txt")
clean_dci_path = os.path.join(BASE_DIR, "clean_dci.txt")
dci = open(dci_path, "r", encoding="utf-8")
clean_dci = open(clean_dci_path, "w", encoding="utf-8")
s =set()
i=1
for line in dci:
    print(f"Processing line {i}")
    i += 1
    line = line.strip()
    if '+' in line:
        for item in line.split('+'):
            s.add(item.strip())
    else:
        s.add(line.strip())

for item in sorted(s):
    clean_dci.write(item + "\n")
dci.close()
clean_dci.close()