import pandas as pd

# Read unmatched DCI names
with open('unmatched_dci.txt', 'r') as f:
    unmatched = f.read().splitlines()

# Load existing CSV
dci = pd.read_csv('classifications.csv')

# Prepare new rows as a DataFrame
new_rows = pd.DataFrame([{
    "dci_name": name,
    "overall_status": "UNKNOWN",
    "trimester_details/T1": "UNKNOWN",
    "trimester_details/T2": "UNKNOWN",
    "trimester_details/T3": "UNKNOWN",
    "trimester_details/DELIVERY": "UNKNOWN",
    "summary": "UNKNOWN",
    "source_url": None
} for name in unmatched])

# Concatenate old and new rows
dci = pd.concat([dci, new_rows], ignore_index=True)

# Save back to CSV (keeps old data + new rows)
dci.to_csv('classifications.csv', index=False)