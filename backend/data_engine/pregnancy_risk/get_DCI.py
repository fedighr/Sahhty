import pandas as pd

# Ouvrir le fichier Excel
df = pd.read_excel("MED CNAM.xlsx")

# Lire toutes les valeurs d'une colonne, par exemple "DCI"
column_values = df["DCI"].tolist()
# Afficher
print(column_values)
f = open('DCI.txt', 'w')
for column in column_values:
    f.write(column+'\n')
    
f.close()