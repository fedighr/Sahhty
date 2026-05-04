import requests
from bs4 import BeautifulSoup
from urllib.parse import quote_plus
from unidecode import unidecode
from rapidfuzz import fuzz
import re
import json
import time

HEADERS = {
    "User-Agent": "ResearchBot - Academic Research on Drug Safety in Pregnancy"
}

GROQ_API_KEY = "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"
GROQ_MODEL = "llama-3.3-70b-versatile"

def normalize(text):
    return unidecode(text.lower().strip())

def get_variations(dci):
    variations = [dci]
    words = dci.strip().split()

    if len(words) >= 2:
        variations.append(" ".join(words[1:] + [words[0]]))
        variations.append(" ".join(words[1:]))

        upper_words = [w.upper() for w in words]
        if "DE" in upper_words:
            idx = upper_words.index("DE")
            before_de = " ".join(words[:idx])
            after_de = " ".join(words[idx+1:])
            variations.append(before_de)
            variations.append(after_de)

    variations.append(f"VACCIN {dci}")

    seen = set()
    unique = []
    for v in variations:
        if v and len(v) > 1 and v not in seen:
            seen.add(v)
            unique.append(v)
    return unique

def extract_candidates(soup):
    candidates = []
    for link in soup.find_all("a", href=True):
        title = link.text.strip()
        if "Grossesse" in title and "Allaitement" not in title:
            if "–" in title:
                clean = title.split("–")[0].strip()
            else:
                match = re.search(r"-(?!.*-)", title)
                if match:
                    clean = title[:match.start()].strip()
                else:
                    clean = title.strip()
            if "=" in clean:
                parts = [p.strip() for p in clean.split("=")]
            else:
                parts = [clean]
            split_parts = []
            for part in parts:
                split_parts.extend([p.strip() for p in re.split(r"/|=", part)])
            candidates.append((split_parts, link['href']))
    return candidates

def match_with_vaccin(dci, parts):
    """Check if any part matches 'VACCIN {dci}' or if dci is contained in any part that starts with VACCIN."""
    for part in parts:
        norm_part = normalize(part)
        if normalize(f"VACCIN {dci}") == norm_part:
            return True
        if norm_part.startswith("vaccin") and normalize(dci) in norm_part:
            return True
    return False

def verify_with_groq(dci_name, result_name):
    prompt = f"In pharmacology, are '{dci_name}' and '{result_name}' the same drug or same active ingredient? Include synonyms, chemical/generic names, brand names, and class names. Answer ONLY YES or NO, nothing else. Do not explain."
    try:
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "model": GROQ_MODEL,
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 5,
                "temperature": 0
            },
            timeout=15
        )
        if response.status_code == 429:
            print("  Groq rate limit hit, waiting 10s...")
            time.sleep(10)
            return verify_with_groq(dci_name, result_name)

        data = response.json()
        if "choices" in data and len(data["choices"]) > 0:
            answer = data["choices"][0]["message"]["content"].strip().upper()
            if "YES" in answer:
                return True
            if "NO" in answer:
                return False
            print(f"  Groq unexpected answer: '{answer}', treating as NO")
            return False
        else:
            print(f"  Groq empty response, status: {response.status_code}, body: {data}")
            return False
    except Exception as e:
        print(f"  Groq error: {e}")
        return False

def search_crat(dci):
    variations = get_variations(dci)
    all_candidates = []

    for variant in variations:
        search_url = f"https://www.lecrat.fr/?s={quote_plus(variant)}"
        try:
            response = requests.get(search_url, headers=HEADERS, timeout=10)
            soup = BeautifulSoup(response.text, "html.parser")
            candidates = extract_candidates(soup)

            if not candidates:
                continue

            if len(candidates) == 1:
                parts, href = candidates[0]

                for part in parts:
                    if normalize(part) == normalize(dci) or any(normalize(v) == normalize(part) for v in variations):
                        return href, "exact", None

                if match_with_vaccin(dci, parts):
                    return href, "vaccin-match", parts[0]

                result_name = parts[0]
                confirmed = verify_with_groq(dci, result_name)
                if confirmed:
                    return href, "single-result-groq-confirmed", result_name
                else:
                    all_candidates.append((parts, href))

            for parts, href in candidates:
                for part in parts:
                    for v in variations:
                        if normalize(v) == normalize(part):
                            return href, "exact", None

                if match_with_vaccin(dci, parts):
                    return href, "vaccin-match", parts[0]

            all_candidates.extend(candidates)

        except Exception as e:
            print(f"  Error searching '{variant}': {e}")

    if all_candidates:
        best_score = 0
        best_href = None
        best_title = None

        for parts, href in all_candidates:
            for part in parts:
                for v in variations:
                    score = fuzz.token_sort_ratio(normalize(v), normalize(part))
                    len_ratio = len(part) / max(len(dci), 1)
                    if len_ratio < 0.5:
                        score *= 0.7
                    if score > best_score:
                        best_score = score
                        best_href = href
                        best_title = part

        if best_score >= 90:
            return best_href, f"fuzzy({best_score:.0f}%)", best_title

        if best_score >= 80:
            confirmed = verify_with_groq(dci, best_title)
            if confirmed:
                return best_href, f"fuzzy-groq-confirmed({best_score:.0f}%)", best_title
            else:
                return None, f"fuzzy-groq-rejected({best_score:.0f}%)", best_title

    return None, "not_found", None

with open('DCI_dataset.txt', 'r') as f:
    lines = [line.strip() for line in f if line.strip()]

results = []

with open('unmatched_dci.txt', 'w') as f_miss:
    for i, dci in enumerate(lines, 1):
        print(f"{i}/{len(lines)} — {dci}")
        link, status, matched_name = search_crat(dci)

        if link:
            print(f"  ✓ {status} → {link}")
            entry = {
                "dci": dci,
                "url": link,
                "status": status
            }
            if matched_name:
                entry["matched_name"] = matched_name
            results.append(entry)
        else:
            print(f"  ✗ {status}")
            f_miss.write(f"{dci}\n")

with open('results.json', 'w', encoding='utf-8') as f_json:
    json.dump(results, f_json, ensure_ascii=False, indent=2)

print(f"\nDone. {len(results)} matched, {len(lines) - len(results)} unmatched.")
