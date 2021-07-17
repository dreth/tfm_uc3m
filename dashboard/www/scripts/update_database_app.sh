#!/bin/bash
system=$(uname -s)
date=''

# Record the date
if [ $system == 'Darwin' ] 
then 
    date=$(date -v-1d +%Y-%m-%d %T)  # MacOS
elif [ $system == 'Linux' ] 
then 
    date=$(date "+%Y-%m-%d %T")  # Linux
else echo "OS not recognized" 
fi

# Browse to API folder to run python scripts
cd '../api'

# Running the python scripts
python3 './query.py'
python3 './dbs_check.py'

# Copying the updated files from the main repo into the cloned data repo
cp -r /tfm_uc3m/data/logs/update_database.log /tfm_uc3m_data/logs/update_database.log
cp -r /tfm_uc3m/data/logs/update_history.log /tfm_uc3m_data/logs/update_history.log
cp -r /tfm_uc3m/data/death.csv /tfm_uc3m_data/death.csv
cp -r /tfm_uc3m/data/pop.csv /tfm_uc3m_data/pop.csv

# Browsing to the cloned data repo to push changes
cd /tfm_uc3m_data

# Staging changes
git add ./death.csv
git add ./pop.csv
git add ./logs/update_database.log
git add ./logs/update_history.log

# Committing changes including the date of the update
git commit -m "updated database at: ${date}"

# Pushing changes to the tfm_uc3m_data repo
git push https://"$GITHUB_USER":"$GITHUB_TOKEN"@github.com/dreth/tfm_uc3m_data.git

# Notifying the user in console
echo "Repo update pushed to GitHub"