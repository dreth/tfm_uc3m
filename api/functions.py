# %% IMPORTING LIBRARIES
import requests
import json
import pandas as pd
import datetime as dt
import numpy as np
from copy import deepcopy

# %% CCAA and Age groups to query
# CCAA
ccaa_list = ['ES11', 'ES12', 'ES13', 'ES21', 'ES22', 'ES23', 'ES24', 'ES3', 'ES41',
             'ES42', 'ES43', 'ES51', 'ES52', 'ES53', 'ES61', 'ES62', 'ES63', 'ES64', 'ES7']

# Age groups
age_groups = ['Y10-14', 'Y15-19', 'Y20-24', 'Y25-29', 'Y30-34', 'Y35-39', 'Y40-44', 'Y45-49', 'Y5-9',
              'Y50-54', 'Y55-59', 'Y60-64', 'Y65-69', 'Y70-74', 'Y75-79', 'Y80-84', 'Y85-89', 'Y_GE90', 'Y_LT5']

# Sexes
sexes = ['M','F','T']

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
            if type(value) == list:
                field = ''.join([f'geo={x}&' for x in value])
            else:
                field = f'geo={value}'
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

# %% CHECK LAST/EARLIEST WEEK UPDATED IN EUROSTAT DEATH DATASET
def check_eurostat_provisional(sex='T', age='Y80-84', ccaa='ES3', earliest=True, lookback=2):
    # check current year
    curr_year = dt.datetime.now().year

    # generate query dict
    query = {
        'dataset': 'demo_r_mwk2_05',  # Name of the dataset
        'sinceTimePeriod': f'{curr_year-lookback}W01',  # Starting week of the study
        'geo': ccaa,                  # CCAAs
        'unit': 'NR',                  # Units (NR = number)
        'sex': sex,
        'age': age
    }

    # obtain response from eurostat using query function
    response = query_eurostat(**query)

    # obtain weeks and status from the response object
    weeks = {k:date for date,k in response['dimension']['time']['category']['index'].items() if 'W99' not in date and 'W53' not in date}
    provisional = {int(k):tag for k,tag in response['status'].items() if int(k) in list(weeks.keys()) and tag == 'p'}

    # obtain earliest and latest date of interest and save corresponding one
    index_of_interest = (list(provisional.keys())[0], list(provisional.keys())[-1])
    if earliest == True:
        date_of_interest = weeks[index_of_interest[0]]
    elif earliest == 'both':
        date_of_interest = (weeks[index_of_interest[0]], weeks[index_of_interest[1]])
    else:
        date_of_interest = weeks[index_of_interest[1]]

    # return earliest provisional data point
    return date_of_interest

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

    # summing marking 53rd weeks to remove
    for idx,w in zip(df.index,df['week']):
        if w == 53:
            df.iloc[idx,5] = 0
    
    # removing 53rd week
    df = df[df['year'] != 0]

    # grouping in order to aggregate W53 with corresponding W01
    df = df.groupby(grouping).sum().reset_index()

    # dropping year_week
    df = df.drop('year_week', axis='columns')

    # returning the dataframe
    return df

# %% QUERY INE DATA TABLES

def query_INE_pop(df_id='9681', start=f'20100101', end='', print_diag=True):
    if print_diag == True:
        print(f'Querying INE table id: {df_id}, starting at: {start[0:4]}-{start[4:6]}-{start[6:]}...\n')
    url = f'https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/{df_id}?date={start}:{end}'
    return json.loads(requests.get(url).text)

# %% CHECK LAST/EARLIEST WEEK UPDATED IN INE POP DATASET
def check_INE_latest(df_id='9681', lookback=2):
    # check current year
    curr_year = dt.datetime.now().year

    # obtain response object
    response = query_INE_pop(df_id=df_id, start=f'{curr_year-lookback}0101', print_diag=False)[0]

    # date conversion to week
    conv = {
        'code_m': {
            26:1,
            27:7
        },
        'code_w':{
            26:'01',
            27:'26'
        }
    }

    # obtain available dates in query
    query_dates = []
    for elem in response['Data']:
        for k,v in elem.items():
            if k == 'Anyo':
                l_year = v
            elif k == 'FK_Periodo':
                l_week = v
        query_dates.append((dt.date(l_year, conv['code_m'][l_week], 1), f'{l_year}W{conv["code_w"][l_week]}'))
    
    # sort the obtained response by date
    # then extract year_week from 2nd element in tuple
    latest_year_week = sorted(query_dates, key=lambda elems: elems[0], reverse=True)[0][1]

    # return resulting date
    return latest_year_week

# %% GENERATE POPULATION DF
def generate_pop_df(raw_data, most_recent_week, date=False):
    """
    raw_data         : json object obtained from the query_INE_pop function
    most_recent_week : 
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
        'Madrid, Comunidad de': 'ES3',
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
        'Canarias': 'ES7'
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
    df = df.rename({'age_group':'age'},axis=1)

    # Performing aggregation on corresponding fields to sum values among same age groups
    df = df.groupby(['ccaa','sex','date','age']).sum().reset_index()

    # appending year
    df['year'] = df['date'].apply(lambda x: x.year)

    # appending week
    df['week'] = df['date'].apply(lambda x: week_dict[x.month])

    # creating marker for unique pop. identifier
    df['marker'] = df['ccaa'] + df['sex'] + df['age']

    # obtain unique markers in a variable
    umarkers = df['marker'].unique()

    # obtain amount of unique years, however, we add one if
    # we end the last marker date in july (so that our 
    # prediction continues until the following year)
    if df.loc[df['marker'] == umarkers[0], 'date'].values[-1].month == 7:
        uyears = df['year'].nunique() + 1
    else:
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
        # obtain array of values matching loop marker and converting it to a list
        dat = df.loc[df['marker'] == umarkers[m]].values
        dat_copy = np.zeros((np.shape(dat)[0]+1,np.shape(dat)[1]), dtype=object)
        dat_copy[0:len(dat_copy)-1,:] = dat

        # add last element by modifying prev. last element values in order to predict a full year after last date
        last_element = deepcopy(dat[-1])

        # modifying last element's date to project to the next 6 month period
        # modifying date
        if last_element[2].month == 7:
            last_element[2] = dt.date(last_element[2].year + 1, 1, last_element[2].day)
            last_element[5] = last_element[5] + 1
            last_element[6] = 1
        else:
            last_element[2] = dt.date(last_element[2].year, 7, last_element[2].day)
            last_element[6] = 26

        # projecting last population using the previous element's ratio
        last_element[4] = int(last_element[4]* (last_element[4]/dat[-2][4]))
                
        # extending elements of dat to include this last modified data point
        dat_copy[-1,:] = last_element
        dat = dat_copy

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
                pop_est = np.linspace(pred_range[0,idx['pop']], pred_range[1,idx['pop']], 28, dtype=np.int64)[1:27]

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

    # removing empty spots
    df = df[df['ccaa'] != 0]

    # only keeping most recentl week
    df.loc[df['year'] == 2021] = df.loc[df['week'] <= most_recent_week]

    # removing nans
    df = df[~df['week'].isnull()].reset_index(drop=True)

    # remove date if date is false
    if date == False:
        df = df.drop('date',axis=1)

    # reorder columns
    df = df[['year','week','ccaa','sex','age','pop']]

    # Returning the resulting dataframe
    return df

# %% FUNCTION TO PERFORM DATASET UPDATE (adds new entries, keeps old useful ones, updates provisional ones)
def perform_update_datasets(curr_path, db_type, updated_dataset):
    """
    curr_path       : path where the current revision of the datasets is located
    db_type         : metric to update, currently it must be either 'deaths' or 'pop'
    updated_dataset : dataframe object as obtained from the generate_df functions, either a death or pop dataset 
    """
    # reading currently available data and replacing/appending only the new data
    curr = pd.read_csv(curr_path)[['year','week','ccaa','sex','age',db_type]]

    # create marker to uniquely identify entries
    curr['mkr'] = curr['year'].astype(str) + curr['week'].astype(str) + curr['sex'] + curr['ccaa'] + curr['age']
    updated_dataset['mkr'] = updated_dataset['year'].astype(str) + updated_dataset['week'].astype(str) + updated_dataset['sex'] + updated_dataset['ccaa'] + updated_dataset['age']

    # values to add correspond to those whose markers are not present in the current version
    to_add = updated_dataset[~updated_dataset['mkr'].isin(curr['mkr'])]

    # we only keep those that we'll update
    updated_dataset = updated_dataset[updated_dataset['mkr'].isin(curr['mkr'])]

    # values to keep correspond to those which have been acquired previously and are no longer provisional
    to_keep = curr[~curr['mkr'].isin(updated_dataset['mkr'].unique())]

    # values to update correspond to those which are still marked as provisional by eurostat
    to_update = curr[curr['mkr'].isin(updated_dataset['mkr'].unique())].reset_index()

    # we update the db_type metric (deaths, pop, etc) for the provisional values
    to_update.loc[to_update['mkr'] == updated_dataset['mkr'],db_type] = updated_dataset.loc[to_update['mkr'] == updated_dataset['mkr'],db_type]

    # we return the previous index of the dataset to concatenate easier
    to_update.index = to_update['index']

    # we drop the index column, as it already served its purpose
    to_update = to_update.drop(['index'], axis=1)

    # joining it all up together
    df = pd.concat([to_keep, to_update, to_add])

    # we drop the marker column, as it already served its purpose
    df = df.drop(['mkr'], axis=1)

    # returning updated df
    return df.reset_index(drop=True)
