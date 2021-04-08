import pandas as pd
import datetime as dt
import numpy as np

# %% First basic filters (removing totals) and renaming cols
# Performing a find and replace to remove dots from totals to avoid
# parsing the values as floats (Who thought it was a good idea to use dots for thousands? Really?)
with open('../../data/population/full_population_data.csv', 'r+', encoding='cp1252') as f:
    dataset = f.read()
    dataset = dataset.replace('.', '')
    f.seek(0)
    f.truncate(0)
    f.write(dataset)

# Reading data after replacing
pop = pd.read_csv('../../data/population/full_population_data.csv', sep='\t')

# Rename cols
pop = pop.rename(columns={
    'Edad simple': 'age',
    'Comunidades y ciudades autónomas': 'ccaa',
    'Sexo': 'sex',
    'Periodo': 'period',
    'Total': 'population'
})

# Excluding totals from age and ccaa
pop = pop[(pop['ccaa'] != 'Total Nacional') & (pop['age'] != 'Total')]

# %% Standardizing identifying values to match Eurostat
# Dictionary to replace INE CCAA names with Eurostat codes
ccaa_eurostat_replace_dict = {
    '12 Galicia': 'ES11',
    '03 Asturias, Principado de': 'ES12',
    '06 Cantabria': 'ES13',
    '16 País Vasco': 'ES21',
    '15 Navarra, Comunidad Foral de': 'ES22',
    '17 Rioja, La': 'ES23',
    '02 Aragón': 'ES24',
    '13 Madrid, Comunidad de': 'ES30',
    '07 Castilla y León': 'ES41',
    '08 Castilla - La Mancha': 'ES42',
    '11 Extremadura': 'ES43',
    '09 Cataluña': 'ES51',
    '10 Comunitat Valenciana': 'ES52',
    '04 Balears, Illes': 'ES53',
    '01 Andalucía': 'ES61',
    '14 Murcia, Región de': 'ES62',
    '18 Ceuta': 'ES63',
    '19 Melilla': 'ES64',
    '05 Canarias': 'ES70'
}

# Dictionary to replace INE sex field with Eurostat's
sex_eurostat_replace_dict = {
    'Ambos sexos': 'T',
    'Hombres': 'M',
    'Mujeres': 'F'
}

# Replacing values for sex and ccaa
pop['ccaa'] = pop['ccaa'].apply(lambda x: ccaa_eurostat_replace_dict[x])
pop['sex'] = pop['sex'].apply(lambda x: sex_eurostat_replace_dict[x])

# %% Parsing non-standard fields
# Parsing INE date field


def parse_INE_date(x):
    strng = x.split('de')
    strng = [w.strip() for w in strng]

    # parse month
    replace_month = {
        'julio': 7,
        'enero': 1
    }

    # return datetime object
    return dt.date(int(strng[2]), replace_month[strng[1]], int(strng[0]))


# Replacing date field with the parsed form
pop['period'] = pd.to_datetime(
    pop['period'].apply(lambda x: parse_INE_date(x)))

# %% Parsing year to simplify grouping by years matching Eurostat's groupings
# Removing "años" from the field
pop['age'] = pop['age'].apply(lambda x: int(x.split(' ')[0]))

# Organizing values of age groups to match Eurostat
# Matching LT5 and GE90 values (less than 5 and greater or equal to 90)
pop['age_group'] = pd.NA
pop.loc[pop['age'] < 5, 'age_group'] = 'Y_LT5'
pop.loc[pop['age'] >= 90, 'age_group'] = 'Y_GE90'

# Using cut to organize the rest of the groups
ages_to_group = pop.loc[pop['age_group'].isna(), 'age'].unique()
age_group_labels = ['Y5-9', 'Y10-14', 'Y15-19', 'Y20-24', 'Y25-29', 'Y30-34', 'Y35-39', 'Y40-44',
                    'Y45-49', 'Y50-54', 'Y55-59', 'Y60-64', 'Y65-69', 'Y70-74', 'Y75-79', 'Y80-84', 'Y85-89']
pop.loc[pop['age_group'].isna(), 'age_group'] = pd.cut(pop['age'], [5, 9, 14, 19,
                                                                    24, 29, 34, 39, 44, 49, 54, 59, 64, 69, 74, 79, 84, 89], include_lowest=True, labels=age_group_labels)

# Removing age, as we now have age groups
pop = pop.drop('age', axis=1)

# %% Performing aggregation on corresponding fields
pop = pop.groupby(['ccaa','sex','period','age_group']).sum().reset_index()

# %% Exporting dataset
pop.to_csv('./population.csv')
