import pdfplumber
import json
import re

SEVERITIES = [
    "CI - ASDEC - APEC",
    "CI - ASDEC - PE",
    "CI - ASDEC",
    "CI - APEC",
    "CI - PE",
    "ASDEC - APEC",
    "ASDEC - PE",
    "Association DECONSEILLEE",
    "ASSOCIATION DECONSEILLEE",
    "Précaution d'emploi",
    "PRÉCAUTION D'EMPLOI",
    "A prendre en compte",
    "A PRENDRE EN COMPTE",
    "Association à prendre en compte",
    "ASSOCIATION À PRENDRE EN COMPTE",
    "Contre-indication",
    "CONTRE-INDICATION",
]

SEVERITY_MAP = {
    "CI - ASDEC - APEC":               "CONTRE_INDICATION",
    "CI - ASDEC - PE":                 "CONTRE_INDICATION",
    "CI - ASDEC":                      "CONTRE_INDICATION",
    "CI - APEC":                       "CONTRE_INDICATION",
    "CI - PE":                         "CONTRE_INDICATION",
    "ASDEC - APEC":                    "DECONSEILLEE",
    "ASDEC - PE":                      "DECONSEILLEE",
    "Association DECONSEILLEE":        "DECONSEILLEE",
    "ASSOCIATION DECONSEILLEE":        "DECONSEILLEE",
    "Précaution d'emploi":             "PRECAUTION_EMPLOI",
    "PRÉCAUTION D'EMPLOI":             "PRECAUTION_EMPLOI",
    "A prendre en compte":             "A_PRENDRE_EN_COMPTE",
    "A PRENDRE EN COMPTE":             "A_PRENDRE_EN_COMPTE",
    "Association à prendre en compte": "A_PRENDRE_EN_COMPTE",
    "ASSOCIATION À PRENDRE EN COMPTE": "A_PRENDRE_EN_COMPTE",
    "Contre-indication":               "CONTRE_INDICATION",
    "CONTRE-INDICATION":               "CONTRE_INDICATION",
}

def parse_block(dci_a, dci_b, block):
    normalized = re.sub(r'\s+', ' ', block).strip()

    severity_found = None
    description = normalized
    recommendation = ""

    for sev in SEVERITIES:
        if sev in normalized:
            severity_found = sev
            parts = normalized.split(sev, 1)
            description = parts[0].strip()
            recommendation = parts[1].strip() if len(parts) > 1 else ""
            break

    return {
        "dci_a":          dci_a,
        "dci_b":          dci_b,
        "severity":       SEVERITY_MAP.get(severity_found, "UNKNOWN"),
        "description":    description,
        "recommendation": recommendation,
    }


def parse_pdf(pdf_path):
    interactions = []

    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages[2:], start=3):
            gray_rects = [
                r for r in page.rects
                if r['non_stroking_color'] == (0.752941, 0.752941, 0.752941)
            ]
            gray_rects.sort(key=lambda r: r['top'])

            if not gray_rects:
                continue

            for i, rect in enumerate(gray_rects):
                cropped_header = page.crop((
                    rect['x0'], rect['top'],
                    rect['x1'], rect['bottom']
                ))
                header_text = cropped_header.extract_text()
                if not header_text:
                    continue
                dci_a = header_text.split('\n')[0].strip()

                top    = rect['bottom']
                bottom = gray_rects[i + 1]['top'] if i + 1 < len(gray_rects) else page.height

                cropped_body = page.crop((0, top, page.width, bottom))
                body_text = cropped_body.extract_text()
                if not body_text:
                    continue

                lines = body_text.split('\n')
                current_dci_b = None
                current_block_lines = []

                for line in lines:
                    stripped = line.strip()
                    if stripped.startswith('+'):
                        if current_dci_b and current_block_lines:
                            block = ' '.join(current_block_lines)
                            interactions.append(parse_block(dci_a, current_dci_b, block))

                        current_dci_b = stripped[1:].strip()
                        current_block_lines = []
                    else:
                        if current_dci_b and stripped:
                            current_block_lines.append(stripped)

                if current_dci_b and current_block_lines:
                    block = ' '.join(current_block_lines)
                    interactions.append(parse_block(dci_a, current_dci_b, block))

    return interactions


if __name__ == "__main__":
    pdf_path = "interactions-medicamenteuses.pdf"
    print("Parsing PDF...")
    interactions = parse_pdf(pdf_path)
    print(f"Extracted {len(interactions)} interactions")

    with open("interactions.json", "w", encoding="utf-8") as f:
        json.dump(interactions, f, ensure_ascii=False, indent=2)

    print("Saved to interactions.json")

    print("\nPreview:")
    for item in interactions[:3]:
        print(json.dumps(item, ensure_ascii=False, indent=2))