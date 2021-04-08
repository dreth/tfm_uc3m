# %% IMPORTING LIBRARIES
import requests
import json
import pandas as pd

# %% CCAA and Age groups to query
# CCAA
ccaa = ['ES11', 'ES12', 'ES13', 'ES21', 'ES22', 'ES23', 'ES24', 'ES3', 'ES41',
        'ES42', 'ES43', 'ES51', 'ES52', 'ES53', 'ES61', 'ES62', 'ES63', 'ES64', 'ES7']

# Age groups
age_groups = ['Y10-14', 'Y15-19', 'Y20-24', 'Y25-29', 'Y30-34', 'Y35-39', 'Y40-44', 'Y45-49', 'Y5-9',
              'Y50-54', 'Y55-59', 'Y60-64', 'Y65-69', 'Y70-74', 'Y75-79', 'Y80-84', 'Y85-89', 'Y_GE90', 'Y_LT5']


# %% Basic boilerplate query dict
query = {
    'dataset': 'demo_r_mwk2_05',  # Name of the dataset
    'sinceTimePeriod': '2010W01',  # Starting week of the study
    'geo': ccaa,                  # CCAAs
    'unit': 'NR'                  # Units (NR = number)
}

# Querying function
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
        if param != 'dataset':
            url = f'{url}&{field}'

    # appending to URL
    return json.loads(requests.get(url).text)


query_eurostat(**query)

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

    # returning the dataframe 
    return pd.DataFrame(df)

# %%
