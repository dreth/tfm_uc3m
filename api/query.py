# %% IMPORTING FUNCTIONS TO USE
from functions import *

# %% SET DATA FOLDER PATH
datapath = '../data'

# %% Basic boilerplate query dict

# get last provisional date
earliest_date = check_eurostat_provisional()
latest_date = check_eurostat_provisional(earliest=False)
latest_prov_date_death = latest_date
earliest_prov_date_death = earliest_date
earliest_prov_date_pop = earliest_date[0:4]

# constructing the query
query = {
    'dataset': 'demo_r_mwk2_05',  # Name of the dataset
    'sinceTimePeriod': earliest_prov_date_death,  # Earliest provisional week found in the deaths database
    'geo': ccaa_list,                  # CCAAs
    'unit': 'NR'                  # Units (NR = number)
}

# %% QUERYING ALL DATASETS AND EXPORTING + DIAGNOSTIC MESSAGES
# logging everything to text file
print('\nSTEP 1 - Querying Eurostat...\n')
with open('../data/logs/update_database.log', 'w+') as f:
    f.write('> DB UPDATE LOG:\n\n> STEP 1 - Querying Eurostat...\n\n')

# Create a list of death datasets for each age+sex to append all to one df
death_datasets = []
for age in age_groups:
    for sex in sexes:
        print(f'Querying deaths for age group: {age}, sex: {sex}...')
        with open('../data/logs/update_database.log', 'r+') as f:
            contents = f.read()
            f.write(f'Querying deaths for age group: {age}, sex: {sex}...\n')
        new_query = {**query, **{'sex':sex, 'age':age}}
        new_df = generate_death_df(query_eurostat(**new_query))
        death_datasets.append(new_df)

# concatenating death datasets
print('\n> STEP 2 - Creating death dataset...\n')
# logging to text file
with open('../data/logs/update_database.log', 'r+') as f:
    contents = f.read()
    f.write('\nSTEP 2 - Creating death dataset...\n')
death = pd.concat(death_datasets).reset_index(drop=True)
most_recent_week = int(latest_prov_date_death[-2:])
# perform database update
death = perform_update_datasets(curr_path=f'{datapath}/death.csv', db_type='deaths', updated_dataset=death)
death.to_csv(f'{datapath}/death.csv')

# obtain pop dataset
print('> STEP 3 - Creating pop dataset...\n')
# logging to text file
with open('../data/logs/update_database.log', 'r+') as f:
    contents = f.read()
    f.write('\nSTEP 3 - Creating pop dataset...\n')
pop_raw = query_INE_pop(start=f'{earliest_prov_date_pop}0101')
pop = generate_pop_df(raw_data=pop_raw, most_recent_week=most_recent_week)
# perform database update
pop = perform_update_datasets(curr_path=f'{datapath}/pop.csv', db_type='pop', updated_dataset=pop)
pop.to_csv(f'{datapath}/pop.csv')

# Finished process
print('\nDone!\n')
# logging to text file and cleaning up
with open('../data/logs/update_database.log', 'w+') as f:
    f.write(f'> Database updated as of: {dt.datetime.now().isoformat(" ")}\n')

# adding update information to the update history log
with open('../data/logs/update_history.log', 'r+') as f:
    contents = f.read()
    f.seek(0,0)
    f.write(f'> Database updated at: {dt.datetime.now().isoformat(" ")}\n' + contents)
