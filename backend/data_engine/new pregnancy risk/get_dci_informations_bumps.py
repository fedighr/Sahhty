import requests
from bs4 import BeautifulSoup
import json
import os

SECTIONS_TO_KEEP = [
    "quick read",
    "risks",
    "will my baby need extra monitoring",
    "are there any risks to my baby if the father",
    "benefits",  
    "no treatment", 
]

def get_bumps_content(url):
    response = requests.get(url, timeout=10)
    soup = BeautifulSoup(response.content.decode("utf-8", errors="replace"), "html.parser")

    for tag in soup(["script", "style", "nav", "header", "footer"]):
        tag.decompose()

    result = {}

    headings = soup.find_all("h2")
    for h2 in headings:
        section_title = h2.get_text(strip=True).lower()

        if any(key in section_title for key in SECTIONS_TO_KEEP):
            content_parts = []
            for sibling in h2.find_next_siblings():
                if sibling.name in ["h2", "h1"]:
                    break
                text = sibling.get_text(separator=" ", strip=True)
                if text:
                    content_parts.append(text)
            result[h2.get_text(strip=True)] = " ".join(content_parts)

    return result


current_folder = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(current_folder, "bumps_matched_lecrat.json"), "r", encoding="utf-8") as f:
    data = json.load(f)

for entry in data:
    dci_name = entry["dci"]
    dci_url = entry["url"]
    print(f"Processing {dci_name} from {dci_url}...")
    entry["bumps_data"] = get_bumps_content(dci_url)

with open(os.path.join(current_folder, "DCI_informations_bumps_new.json"), "w", encoding="utf-8") as f_out:
    json.dump(data, f_out, ensure_ascii=False, indent=2)

print("Done!")