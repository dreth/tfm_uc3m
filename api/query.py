# %% IMPORTING LIBRARIES
import requests
import json
import pandas as pd
import datetime as dt
import numpy as np

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

# %% GENERATE DEATH DF
def generate_death_df(raw_data, date=False):
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

    # if date is specified to be included
    if date == True:
        df['date'] = [dt.date.fromisocalendar(x,y,5) for x,y in zip(df['year'],df['week'])]
        grouping = ['year_week','date','year','week','ccaa','sex','age']
    else:
        grouping = ['year_week','year','week','ccaa','sex','age']

    # summing 53rd week with 1st week of following year
    for idx,y,w in zip(df.index,df['year'], df['week']):
        if w == 53:
            df.iloc[idx,0] = f'{y+1}W01'
            df.iloc[idx,5] = y+1
            df.iloc[idx,6] = 1

    # grouping in order to aggregate W53 with corresponding W01
    df = df.groupby(grouping).sum().reset_index()

    # dropping year_week
    df = df.drop('year_week', axis='columns')

    # returning the dataframe
    return df

# %% QUERY INE DATA TABLES


def query_INE_pop(df_id='9681', start='20100101', end=''):
    url = f'https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/{df_id}?date={start}:{end}'
    return json.loads(requests.get(url).text)


# %% GENERATE POPULATION DF

def generate_pop_df(raw_data, date=False):
    """
    """
    # column fields
    df = {
        'pop': [],
        'ccaa': [],
        'date': [],
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

    # week reference
    week_dict = {
        1:1,
        7:26
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
            date_entry = dt.date(
                data_point['Anyo'],
                date_ref[data_point['FK_Periodo']][0],
                date_ref[data_point['FK_Periodo']][1]
            )
            df['date'].append(date_entry)

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

    # appending year
    df['year'] = df['date'].apply(lambda x: x.year)

    # appending week
    df['week'] = df['date'].apply(lambda x: week_dict[x.month])

    # creating marker for unique pop. identifier
    df['marker'] = df['ccaa'] + df['sex'] + df['age_group']

    # obtain unique markers in a variable
    umarkers = df['marker'].unique()
    uyears = df['year'].nunique()

    # indexes for df_array
    idx = {
        'pop':4,
        'week':6
    }

    # weekly population prediction
    # Size of the new df will be 52 (weeks in a year) times amount of ccaa+sex+age group times amount of
    # unique years
    df_array = np.zeros((52*len(umarkers)*uyears,8), dtype=object)

    # main loop
    for m in range(len(umarkers)):
        # obtain array of values matching loop marker
        dat = df.loc[df['marker'] == umarkers[m]].values

        # reducing entries by one to simplify the code
        entries = len(dat)-1

        # looping through the matched values for marker m
        for i in range(entries):
            # obtaining the prediction range (rolling window of 2)
            pred_range = dat[i:i+2,]

            # obtaining starting week (either 1 or 26)
            week_start = dat[i,idx['week']]
            
            # creating a new array for the current marker selection
            new_p = np.repeat(pred_range[0,:][np.newaxis,:], 26, 0)

            # if week starts at one we assign week numbers from 1-26, else 27-52
            if week_start == 1:
                # assigning week number
                new_p[:,idx['week']] = np.linspace(1,26,26, dtype=np.int64)

                # estimating the population
                pop_est = np.linspace(pred_range[0,idx['pop']], pred_range[1,idx['pop']], 26, dtype=np.int64)
            else:
                # assigning week number
                new_p[:,idx['week']] = np.linspace(27,52,26, dtype=np.int64)

                # estimating the population, we do not intend to repeat 26th week's value, so we select from index
                # 1 and onwards
                pop_est = np.linspace(pred_range[0,idx['pop']], pred_range[1,idx['pop']], 27, dtype=np.int64)[1:]

            # replace column of new_p with the estimated population
            new_p[:,idx['pop']] = pop_est

            # We index the element of the array corresponding to the marker in question 
            df_array[52*uyears*m+26*i:52*uyears*m+26*(i+1),:] = new_p

        # we obtain the last entry (as there will always be at least one period to predict on)
        last_val = dat[entries]

        # We obtain the ending week (week to forecast from)
        week_end = dat[entries,idx['week']]

        # we obtain the ratios forward by dividing the populations of the period by the starting pop of the previous one
        ratios_forward = pop_est/pop_est[0]

        # obtain the ratios forward and obtain the mean for the last one (as to avoid repetition of the previous value)
        new_p = np.repeat(last_val[np.newaxis,:], 26, 0)
        ratios_forward[0:len(ratios_forward)-2] = ratios_forward[1:len(ratios_forward)-1]
        ratios_forward[len(ratios_forward)-1] = np.mean(ratios_forward[0:len(ratios_forward)-2])

        # if week ends at one we assign week numbers from 1-26, else 27-52
        if week_end == 1:   
            new_p[:,idx['week']] = np.linspace(1,26,26, dtype=np.int64)
        else:
            new_p[:,idx['week']] = np.linspace(27,52,26, dtype=np.int64)

        # add the population estimation to the last section of each marker (as it is a forecast)
        pop_est = (ratios_forward*last_val[idx['pop']]).astype('int64')
        new_p[:,idx['pop']] = pop_est
        df_array[52*uyears*m+26*entries:52*uyears*m+26*(entries+1),:] = new_p
    
    # making df_array a dataframe
    df_array = pd.DataFrame(df_array)
    df_array.columns = df.columns
    df = df_array
    df = df.drop('marker',axis=1)

    # remove date if date is false
    if date == False:
        df = df.drop('date',axis=1)

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
death.to_csv('../data/death.csv')

# obtain pop dataset
pop = generate_pop_df(query_INE_pop())
pop.to_csv('../data/pop.csv')