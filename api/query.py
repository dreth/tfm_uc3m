# %% IMPORTING LIBRARIES
import requests
import json
import pandas as pd
import datetime as dt

# %% CCAA and Age groups to query
# CCAA
ccaa_list = ['ES11', 'ES12', 'ES13', 'ES21', 'ES22', 'ES23', 'ES24', 'ES3', 'ES41',
             'ES42', 'ES43', 'ES51', 'ES52', 'ES53', 'ES61', 'ES62', 'ES63', 'ES64', 'ES7']

# Age groups
age_groups = ['Y10-14', 'Y15-19', 'Y20-24', 'Y25-29', 'Y30-34', 'Y35-39', 'Y40-44', 'Y45-49', 'Y5-9',
              'Y50-54', 'Y55-59', 'Y60-64', 'Y65-69', 'Y70-74', 'Y75-79', 'Y80-84', 'Y85-89', 'Y_GE90', 'Y_LT5']

# Sexes
sexes = ['M','F','T']

# %% Basic boilerplate query dict
query = {
    'dataset': 'demo_r_mwk2_05',  # Name of the dataset
    'sinceTimePeriod': '2010W01',  # Starting week of the study
    'geo': ccaa_list,                  # CCAAs
    'unit': 'NR'                  # Units (NR = number)
}

# %% QUERY EUROSTAT FUNCTION
def query_eurostat(**kwargs):
    """
    """
    # Iterating through kwargs to fill URL fields
    for param, value in kwargs.items():
        # URL
        if param == 'dataset':
            url = f'http://ec.europa.eu/eurostat/wdds/rest/data/v2.1/json/en/{value}?'
        if param == 'sinceTimePeriod':
            field = f'sinceTimePeriod={value}&'
        if param == 'geo':
            field = ''.join([f'geo={x}&' for x in value])
        if param == 'age':
            field = f'age={value}'
        if param == 'unit':
            field = f'unit={value}'
        if param == 'sex':
            field = f'sex={value}'
        if param != 'dataset':
            url = f'{url}&{field}'

    # appending to URL
    return json.loads(requests.get(url).text)

# %% GENERATE DEATH DF
def generate_death_df(raw_data):
    """
    """
    # column fields
    fields = {
        'region_codes': list(raw_data['dimension']['geo']['category']['label'].keys()),
        'age_group': list(raw_data['dimension']['age']['category']['label'].keys())[0],
        'sex_group': list(raw_data['dimension']['sex']['category']['label'].keys())[0],
        'timeframes': [x for x in raw_data['dimension']['time']['category']['index'].keys() if 'W99' not in x],
        'values': list(raw_data['value'].values())
    }

    # amount of values in the query
    value_amount = len(fields['values'])
    region_code_amount = len(fields['region_codes'])

    # ratio of values and regions = total amount of weeks queried
    weeks_queried = int(value_amount/region_code_amount)

    # fixing timeframes to exclude an ongoing week (last week queried)
    fields['timeframes'] = fields['timeframes'][:(weeks_queried)]

    # dataframe
    df = {
        'year_week': fields['timeframes']*region_code_amount,
        'deaths': fields['values'],
        'ccaa': sum([[x]*weeks_queried for x in fields['region_codes']], []),
        'sex': [fields['sex_group']]*value_amount,
        'age': [fields['age_group']]*value_amount
    }

    # separating year_week into year and week cols
    df = pd.DataFrame(df)
    df['year'] = df['year_week'].apply(lambda x: x.split('W')[0]).astype(int)
    df['week'] = df['year_week'].apply(lambda x: x.split('W')[1]).astype(int)
    df['date'] = [dt.date.fromisocalendar(x,y,5) for x,y in zip(df['year'],df['week'])]

    # summing 53rd week with 1st week of following year
    for idx,y,w in zip(df.index,df['year'], df['week']):
        if w == 53:
            df.iloc[idx,0] = f'{y+1}W01'
            df.iloc[idx,5] = y+1
            df.iloc[idx,6] = 1

    # grouping in order to aggregate W53 with corresponding W01
    df = df.groupby(['year_week','date','year','week','ccaa','sex','age']).sum().reset_index()

    # dropping year_week
    df = df.drop('year_week', axis='columns')

    # returning the dataframe
    return df

# %% QUERY INE DATA TABLES


def query_INE_pop(df_id='9681', start='20020101', end=''):
    url = f'https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/{df_id}?date={start}:{end}'
    return json.loads(requests.get(url).text)


# %% GENERATE POPULATION DF

def generate_pop_df(raw_data):
    """
    """
    # column fields
    df = {
        'date': [],
        'pop': [],
        'ccaa': [],
        'sex': [],
        'age': []
    }

    # Date reference field
    date_ref = {
        26: (1, 1),
        27: (7, 1)
    }

    # CCAA reference
    ccaa_eurostat_replace_dict = {
        'Galicia': 'ES11',
        'Asturias, Principado de': 'ES12',
        'Cantabria': 'ES13',
        'País Vasco': 'ES21',
        'Navarra, Comunidad Foral de': 'ES22',
        'Rioja, La': 'ES23',
        'Aragón': 'ES24',
        'Madrid, Comunidad de': 'ES30',
        'Castilla y León': 'ES41',
        'Castilla - La Mancha': 'ES42',
        'Extremadura': 'ES43',
        'Cataluña': 'ES51',
        'Comunitat Valenciana': 'ES52',
        'Balears, Illes': 'ES53',
        'Andalucía': 'ES61',
        'Murcia, Región de': 'ES62',
        'Ceuta': 'ES63',
        'Melilla': 'ES64',
        'Canarias': 'ES70'
    }

    # Sex reference
    sex_dict = {
        'Hombres':'M',
        'Mujeres':'F',
        'Total':'T'
    }

    for entry in raw_data:
        # Splitting metadata by '. ' element in Nombre string entry
        if 'Total Nacional' in entry['Nombre'] or 'Todas las edades' in entry['Nombre']:
            continue
        metadata = entry['Nombre'].split('. ')

        # Obtaining key values from Nombre metadata
        if '100 y más años' in entry['Nombre']:
            sex = sex_dict[metadata[0]]
            age = int(metadata[1].split(' ')[0])
            ccaa = ccaa_eurostat_replace_dict[metadata[2]]
        else:
            age = int(metadata[0].split(' ')[0])
            ccaa = ccaa_eurostat_replace_dict[metadata[1]]
            sex = sex_dict[metadata[2]]

        # Data loop to extract values
        for data_point in entry['Data']:
            # appending population number
            df['pop'].append(int(data_point['Valor']))

            # appending full date
            df['date'].append(dt.date(
                data_point['Anyo'],
                date_ref[data_point['FK_Periodo']][0],
                date_ref[data_point['FK_Periodo']][1]
            ))

            # appending age, cca and sex
            df['age'].append(age)
            df['ccaa'].append(ccaa)
            df['sex'].append(sex)

    # converting the dict to dataframe
    df = pd.DataFrame(df)

    # replacing age groups with Eurostat format
    df['age_group'] = pd.NA
    df.loc[df['age'] < 5, 'age_group'] = 'Y_LT5'
    df.loc[df['age'] >= 90, 'age_group'] = 'Y_GE90'

    # Using cut to organize the rest of the age groups
    ages_to_group = df.loc[df['age_group'].isna(), 'age'].unique()
    age_group_labels = ['Y5-9', 'Y10-14', 'Y15-19', 'Y20-24', 'Y25-29', 'Y30-34', 'Y35-39', 'Y40-44',
                        'Y45-49', 'Y50-54', 'Y55-59', 'Y60-64', 'Y65-69', 'Y70-74', 'Y75-79', 'Y80-84', 'Y85-89']
    df.loc[df['age_group'].isna(), 'age_group'] = pd.cut(df['age'], [5, 9, 14, 19,
                                                                        24, 29, 34, 39, 44, 49, 54, 59, 64, 69, 74, 79, 84, 89], include_lowest=True, labels=age_group_labels)

    # Removing age, as we now have age groups
    df = df.drop('age', axis=1)

    # Performing aggregation on corresponding fields to sum values among same age groups
    df = df.groupby(['ccaa','sex','date','age_group']).sum().reset_index()

    # Returning the resulting dataframe
    return df

# %% QUERYING ALL DATASETS AND EXPORTING
# Create a list of death datasets for each age+sex to append all to one df
death_datasets = []
for age in age_groups:
    for sex in sexes:
        new_query = {**query, **{'sex':sex, 'age':age}}
        new_df = generate_death_df(query_eurostat(**new_query))
        death_datasets.append(new_df)

# concatenating death datasets
death = pd.concat(death_datasets)
death.to_csv('death.csv')

# obtain pop dataset
pop = generate_pop_df(query_INE_pop())
pop.to_csv('pop.csv')