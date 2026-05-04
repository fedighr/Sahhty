import pdfplumber

with pdfplumber.open("interactions-medicamenteuses.pdf") as pdf:
    with open("severities.txt", "w", encoding="utf-8") as f:
        for page in pdf.pages[5:6]:
            for rect in page.rects:
                if rect['non_stroking_color'] == (0.752941, 0.752941, 0.752941):
                    top    = rect['bottom']
                    bottom = page.height

                    cropped_body = page.crop((0, top, page.width, bottom))
                    body_text = cropped_body.extract_text()
                    if not body_text:
                        continue

                    for line in body_text.split('\n'):
                        line = line.strip()
                        if any(k in line for k in [
                            "DECONSEILLEE", "emploi", "compte",
                            "indication", "APEC", "ASDEC", "PE"
                        ]):
                            f.write(line + '\n')

print("Saved to severities.txt")