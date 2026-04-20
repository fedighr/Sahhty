f=open("unmatched_dci.txt","r")
f2=open("lecrat_unsafe_DCI.txt","r")
unmatched_dcis = set(line.strip() for line in f if line.strip())
lecrat_unsafe_dcis = set(line.strip() for line in f2 if line.strip())
intersection = unmatched_dcis.intersection(lecrat_unsafe_dcis)
print("DCIs présents dans les deux fichiers :")
for dci in intersection:
    print(dci)