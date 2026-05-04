import requests
from bs4 import BeautifulSoup
import re
#from groq import Groq
#import ftfy
import json
import os


def get_page_text(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.content.decode("utf-8", errors="replace"), "html.parser")
    for tag in soup(["script", "style", "nav", "header", "footer"]):
        tag.decompose()

    return soup.get_text(separator="\n", strip=True)

def check_dci_safety(dci_name, dci_url):
    """
    client = Groq(api_key="")
    page_text = get_page_text(dci_url)
    prompt = f
You are a clinical pharmacology expert specialized in drug safety during pregnancy.

You will be given the URL of a page from the CRAT website (lecrat.fr), which contains detailed information about the safety of a specific drug (DCI) during pregnancy.

Your task:
1. Read and analyze the full content of the provided CRAT page.
2. Extract the drug name (DCI).
3. Based on the medical information on the page, determine the safety classification:
   - SAFE: The drug is considered safe to use during pregnancy with no significant risk reported.
   - CAUTION: The drug can be used during pregnancy but with precautions, monitoring, or limited to specific conditions.
   - UNSAFE: The drug is contraindicated or poses significant risk to the mother or fetus during pregnancy.
4. Identify if the classification applies to ALL trimesters or specific ones:
   - T1 = First trimester (weeks 1-12)
   - T2 = Second trimester (weeks 13-26)
   - T3 = Third trimester (weeks 27-40)
   - DELIVERY = At the time of birth

Important rules:
- Base your classification ONLY on the text content provided below, not on general medical knowledge.
- If a drug is SAFE in some trimesters but UNSAFE in others, reflect that accurately per trimester.
- If the page mentions the drug is not recommended or should be avoided in a specific period, classify that period as UNSAFE.
- If data is insufficient or the page says "insufficient data", classify as CAUTION.
- Always write the summary in French.
- Never leave a field empty. If unknown, write "UNKNOWN".

Return your response STRICTLY in this JSON format and nothing else:

{{
  "dci_name": "<name of the drug>",
  "overall_status": "<SAFE | CAUTION | UNSAFE>",
  "trimester_details": {{
    "T1": "<SAFE | CAUTION | UNSAFE | NOT_APPLICABLE>",
    "T2": "<SAFE | CAUTION | UNSAFE | NOT_APPLICABLE>",
    "T3": "<SAFE | CAUTION | UNSAFE | NOT_APPLICABLE>",
    "DELIVERY": "<SAFE | CAUTION | UNSAFE | NOT_APPLICABLE>"
  }},
  "summary": "<1-2 sentence plain language explanation of why this classification was given>",
  "source_url": "{dci_url}"
}}

PAGE CONTENT:
{page_text}
    
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": prompt}]
    )
    
    response_text = ftfy.fix_text(response.choices[0].message.content).strip()
    
    response_text = re.sub(r'^```[\w]*\n?', '', response_text)
    response_text = re.sub(r'\n?```$', '', response_text)
    response_text = response_text.strip()
    try:
        result = json.loads(response_text)
        return result
    except json.JSONDecodeError:
        return {"error": "Failed to parse model response as JSON", "raw_response": response_text}
    except Exception as e:
        return {"error": str(e), "raw_response": response_text}

    """
    value = get_page_text(dci_url)
    return {dci_name: value, "link": dci_url}  

def save_result(result: dict, filename="results.json"):
    if os.path.exists(filename) and os.path.getsize(filename) > 0:
        with open(filename, "r", encoding="utf-8") as f:
            data = json.load(f)
    else:
        data = []

    data.append(result)

    with open(filename, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)


f=open('get_link_medecine.txt','r')
f2=open('get_safty_status.txt','w', encoding="utf-8")

line=f.readline()
i=1

while(line!=""):
    print(str(i)+"/470")
    line=line.strip()
    dci_name, url = line.split(": ", 1)
    if url == "None":
        f2.write(f"{dci_name}: No CRAT page available\n")
    else:
        safety_info = check_dci_safety(dci_name, url)
        save_result(safety_info)
    line=f.readline()
    i += 1
f.close()
f2.close()    