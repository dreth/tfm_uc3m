# %% IMPORTING LIBRARIES
import datetime as dt
import json
import requests

# %% QUERY EUROSTAT FUNCTION
def query_eurostat(**kwargs):
    # Iterating through kwargs to fill URL fields
    for param, value in kwargs.items():
        # URL
        if param == 'dataset':
            url = f'http://ec.europa.eu/eurostat/wdds/rest/data/v2.1/json/en/{value}?'
        elif param == 'sinceTimePeriod':
            field = f'sinceTimePeriod={value}&'
        elif param == 'geo':
            field = ''.join([f'geo={x}&' for x in value])
        elif param == 'age':
            field = f'age={value}'
        elif param == 'unit':
            field = f'unit={value}'
        elif param == 'sex':
            field = f'sex={value}'
        # appending to URL
        if param != 'dataset':
            url = f'{url}&{field}'

    # appending to URL
    return json.loads(requests.get(url).text)

# %% CHECK LAST WEEK UPDATED IN EUROSTAT DEATH DATASET
# checks the last updated week in eurostat and logs it to a log file
def check_last_date_eurostat(sex='T', age='Y80-84', ccaa=['ES3','ES51']):
    # check current year
    curr_year = dt.datetime.now().year

    # generate query dict
    query = {
        'dataset': 'demo_r_mwk2_05',  # Name of the dataset
        'sinceTimePeriod': f'{curr_year}W01',  # Starting week of the study
        'geo': ccaa,                  # CCAAs
        'unit': 'NR',                  # Units (NR = number)
        'sex': sex,
        'age': age
    }

    # obtain response from eurostat using query function
    response = query_eurostat(**query)

    # obtain weeks and status from the response object
    weeks = response['dimension']['time']['category']['index']

    # obtain only weeks of interest and their respective index
    weeks_of_interest = [x for x in weeks.keys() if int(x[-2:]) >= 1 and int(x[-2:]) <= 52 and int(x[:4]) == curr_year]
    weeks_of_interest_num = [int(x[-2:]) for x in weeks_of_interest]
    weeks_queried_idx = [weeks[x] for x in weeks_of_interest]

    # fixing status dict in order to have keys as int
    status_value = {weeks_of_interest_num[int(x)-1]:y for x,y in response['status'].items() if int(x) in weeks_queried_idx}
    
    # check maximum week that corresponds with an element different to ':', as this represents an empty point
    last_week = max([x for x,y in status_value.items() if y != ':'])

    # return diagnostic string
    return f'Last date obtainable from Eurostat: {curr_year}, week: {last_week}'

# %% RUN SCRIPT AND UPDATE LOG FILE
with open('./logs/last_eurostat_update.log', 'w+') as f:
    f.write(f'{check_last_date_eurostat()}\n')