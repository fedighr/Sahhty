import requests
from bs4 import BeautifulSoup
import re
import json
import os

def get_page_text(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.content.decode("utf-8", errors="replace"), "html.parser")
    for tag in soup(["script", "style", "nav", "header", "footer"]):
        tag.decompose()

    return soup.get_text(separator="\n", strip=True)

current_folder = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(current_folder, "results.json"), "r", encoding="utf-8") as f:
    data = json.load(f)

with open(os.path.join(current_folder, "DCI_informations.json"), "w", encoding="utf-8") as f_out:
    for entry in data:
        dci_name = entry["dci"]
        dci_url = entry["url"]
        print(f"Processing {dci_name} from {dci_url}...")
        page_text = get_page_text(dci_url)
        entry["page_text"] = page_text
    json.dump(data, f_out, ensure_ascii=False, indent=2)
