# %% IMPORTING FUNCTIONS TO USE
from functions import check_eurostat_provisional, check_INE_latest

# %% RUN SCRIPT AND UPDATE LOG FILES
print('\nCalculating database information...\n')

# obtaining eurostat info
eurostat_dates = check_eurostat_provisional(earliest='both')

# logging dates
with open('./logs/last_eurostat_update.log', 'w+') as f:
    latest_date = eurostat_dates[1]
    f.write(f'Last date obtainable from Eurostat DB: {latest_date[0:4]}, week: {latest_date[-2:]}')

with open('./logs/last_ine_update.log', 'w+') as f:
    latest_date = check_INE_latest()
    f.write(f'Last date obtainable from INE DB: {latest_date[0:4]}, week: {latest_date[-2:]}')

with open('./logs/earliest_eurostat_provisional.log', 'w+') as f:
    earliest_date = eurostat_dates[0]
    f.write(f'Earliest provisional date from Eurostat DB: {earliest_date[0:4]}, week: {earliest_date[-2:]}')

# done (:
print('\nDatabase information obtained, Check DB info section for more information\n')