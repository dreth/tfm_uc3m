# %% IMPORTING FUNCTIONS TO USE
from functions import check_eurostat_provisional, check_INE_latest

# %% RUN SCRIPT AND UPDATE LOG FILES
with open('./logs/last_eurostat_update.log', 'w+') as f:
    latest_date = check_eurostat_provisional(earliest=False)
    f.write(f'Last date obtainable from Eurostat DB: {latest_date[0:4]}, week: {latest_date[-2:]}')

with open('./logs/last_ine_update.log', 'w+') as f:
    latest_date = check_INE_latest()
    f.write(f'Last date obtainable from INE DB: {latest_date[0:4]}, week: {latest_date[-2:]}')

with open('./logs/earliest_eurostat_provisional.log', 'w+') as f:
    latest_date = check_eurostat_provisional(earliest=True)
    f.write(f'Earliest provisional date from Eurostat DB: {latest_date[0:4]}, week: {latest_date[-2:]}')
