# %% CC AA parsing
import pandas as pd
import numpy as np
import pickle
import json

# importing data
# data1 = pd.read_csv('../deaths/20_24/per_ccaa_2000_2020_males_20_24.tsv', sep='\t')

# guide for CCAAs
tags = [x.split(',')[-1] for x in data1.iloc[:,0]]
names = ['Galicia', 'Principado de Asturias', 'Cantabria', 'Pais Vasco', 'Comunidad Floral de Navarra', 'La Rioja', 'Aragón', 'Comunidad de Madrid', 'Castilla y León', 'Castilla-la Mancha', 'Extremadura', 'Cataluña', 'Comunitat Valenciana', 'Illes Balears', 'Andalucía', 'Región de Murcia', 'Ciudad de Ceuta', 'Ciudad de Melilla', 'Canarias']

# dictionary as guide
guide_ccaa = {t:n for t,n in zip(tags, names)}

# exporting binarized pickle
with open('./guide_ccaa_python_dict.p', 'wb') as f:
    pickle.dump(guide_ccaa, f)

# exporting json
with open('./guide_ccaa.json', 'w') as f:
    json.dump(guide_ccaa, f)