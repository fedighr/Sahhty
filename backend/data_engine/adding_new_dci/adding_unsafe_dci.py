import django
import pandas as pd
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from dci.models import DCI

current_folder = os.path.dirname(os.path.abspath(__file__))
unmatched_path = os.path.join(current_folder, 'unmatched_dci.csv')
df = pd.read_csv(unmatched_path)

unsafe_dci = df['Unsafe'].to_list()
not_found = []
i=1
for dci_name in unsafe_dci:
    print(f"Processing DCI {i}/{len(unsafe_dci)}: {dci_name}")
    if pd.notna(dci_name):
        dci_name = dci_name.strip()
        if not DCI.objects.filter(name=dci_name).exists():
            not_found.append(dci_name)
    i += 1

print(f"DCIs not found: {len(not_found)}")
for dci_name in not_found:
    print(f" - {dci_name}")