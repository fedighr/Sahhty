import json
import requests
import time

GROQ_API_KEY = "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"
GROQ_MODEL = "llama-3.3-70b-versatile"
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"

def classify_dci(dci_name, page_text, source_url):
    prompt = f"""You are a clinical pharmacology expert specialized in drug safety during pregnancy.

Analyze the CRAT website page content below and classify the safety of the drug during pregnancy.

CLASSIFICATION LABELS:
- SAFE: No significant risk reported, drug can be used without major concerns.
- CAUTION: Drug can be used but requires precautions, monitoring, or is limited to specific conditions or routes.
- UNSAFE: Drug is contraindicated or poses significant risk to mother or fetus.
- NOT_APPLICABLE: No information relevant to this period.

TRIMESTER DEFINITIONS:
- T1: First trimester (weeks 1-12)
- T2: Second trimester (weeks 13-26)
- T3: Third trimester (weeks 27-40)
- DELIVERY: At the time of birth

CLASSIFICATION RULES:
1. Base classification ONLY on the page content below, not on general medical knowledge.
2. Classify each trimester independently based on explicit information in the text.
3. These phrases are strong SAFE signals:
   - "quel que soit le terme" or "quel que soit le terme de la grossesse" → all trimesters SAFE
   - "aucun effet malformatif n'est retenu" → T1 is SAFE
   - "aucun événement particulier fœtal ou néonatal n'a été rapporté" → T2 and T3 are SAFE
   - "Rassurer la patiente" → SAFE in that context
4. A restriction that applies to a specific route of administration or a specific use case (e.g. continuous daily preventive use) does NOT make the whole trimester CAUTION or UNSAFE.
5. Always prioritize the general conclusion in the "EN PRATIQUE" section over specific edge case sentences.
6. If data is insufficient or the page says to contact CRAT, classify as CAUTION.
7. Never leave a field empty. Use "UNKNOWN" if truly unclear.
8. Write the summary in French.

OVERALL STATUS RULE (STRICT - NO EXCEPTIONS):
Derive overall_status MATHEMATICALLY from trimester_details:
- ANY trimester is UNSAFE → overall_status = UNSAFE
- NO trimester is UNSAFE but ANY is CAUTION → overall_status = CAUTION
- ALL trimesters are SAFE or NOT_APPLICABLE → overall_status = SAFE
A contradiction between overall_status and trimester_details is FORBIDDEN.

Return ONLY this JSON, no markdown, no explanation:

{{
  "dci_name": "{dci_name}",
  "overall_status": "<SAFE | CAUTION | UNSAFE>",
  "trimester_details": {{
    "T1": "<SAFE | CAUTION | UNSAFE | NOT_APPLICABLE>",
    "T2": "<SAFE | CAUTION | UNSAFE | NOT_APPLICABLE>",
    "T3": "<SAFE | CAUTION | UNSAFE | NOT_APPLICABLE>",
    "DELIVERY": "<SAFE | CAUTION | UNSAFE | NOT_APPLICABLE>"
  }},
  "summary": "<1-2 sentence plain language explanation in French>",
  "source_url": "{source_url}"
}}

PAGE CONTENT:
{page_text}"""

    try:
        response = requests.post(
            GROQ_URL,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "model": GROQ_MODEL,
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 1000,
                "temperature": 0
            },
            timeout=30
        )

        if response.status_code == 429:
            return "RATE_LIMIT", None

        data = response.json()
        if "choices" not in data or len(data["choices"]) == 0:
            print(f"  Groq empty response: {data}")
            return "ERROR", None

        raw = data["choices"][0]["message"]["content"].strip()
        raw = raw.replace("```json", "").replace("```", "").strip()
        parsed = json.loads(raw)
        return "OK", parsed

    except json.JSONDecodeError as e:
        print(f"  JSON parse error for '{dci_name}': {e}")
        return "ERROR", None
    except Exception as e:
        print(f"  Error for '{dci_name}': {e}")
        return "ERROR", None


with open("DCI_informations.json", "r", encoding="utf-8") as f:
    entries = json.load(f)

try:
    with open("classifications.json", "r", encoding="utf-8") as f:
        classifications = json.load(f)
    already_done = {c["dci_name"] for c in classifications}
    print(f"Resuming — {len(already_done)} already classified.")
except FileNotFoundError:
    classifications = []
    already_done = set()

failed = []

for i, entry in enumerate(entries, 1):
    dci = entry.get("dci", "")
    url = entry.get("url", "")
    page_text = entry.get("page_text", "")

    if dci in already_done:
        print(f"{i}/{len(entries)} — {dci} (skipped, already done)")
        continue

    print(f"{i}/{len(entries)} — {dci}")

    if not page_text:
        print(f"  ✗ No page text, skipping")
        failed.append(dci)
        continue

    status, classification = classify_dci(dci, page_text, url)

    if status == "RATE_LIMIT":
        print(f"  ⚠ Rate limit hit — saving progress and stopping.")
        break

    if status == "OK" and classification:
        print(f"  ✓ {classification.get('overall_status', '?')}")
        classifications.append(classification)
        already_done.add(dci)
    else:
        print(f"  ✗ Classification failed")
        failed.append(dci)

with open("classifications.json", "w", encoding="utf-8") as f:
    json.dump(classifications, f, ensure_ascii=False, indent=2)

if failed:
    with open("classification_failed.txt", "w", encoding="utf-8") as f:
        for dci in failed:
            f.write(f"{dci}\n")

print(f"\nDone. {len(classifications)} classified, {len(failed)} failed.")