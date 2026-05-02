f = open('DCI.txt', 'r')
f2 = open('DCI_dataset.txt', 'w')

ch = f.readline()

while ch != "":
    ch = ch.strip()
    if not ch.startswith('#'):
        ch = ch.replace('VACCIN:', '').strip()
        if '+' in ch:
            for item in ch.split('+'):
                f2.write(item.strip() + '\n')
        elif '/' in ch:
            for item in ch.split('/'):
                f2.write(item.strip() + '\n')
        elif '-' in ch:
            for item in ch.split('-'):
                f2.write(item.strip() + '\n')
        elif ':' in ch:
            f2.write(ch[ch.find(':')+1:].strip() + '\n')
        else:
            f2.write(ch + '\n')
    ch = f.readline()

f.close()
f2.close()
f2 = open('DCI_dataset.txt', 'r')
ch=f2.readline()
unique_dcis = set()
while ch != "":
    ch = ch.strip()
    if ch:
        unique_dcis.add(ch)
    ch = f2.readline()
f2.close()
with open('DCI_dataset.txt', 'w') as f2:
    for dci in sorted(unique_dcis):
        f2.write(dci + '\n')
f2.close()
print('done!')