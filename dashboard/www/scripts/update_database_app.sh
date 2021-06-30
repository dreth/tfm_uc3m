#!/bin/bash
system=$(uname -s)
date=''

if [ $system == 'Darwin' ]
then
  date=$(date -v-1d +%Y-%m-%d %T)  # MacOS
elif [ $system == 'Linux' ]
then
  date=$(date +%Y-%m-%d %T -d "1 day ago")  # Linux
else
  echo "System not recognized!" 1>&2
  exit 64
fi

cd '../api'
python3 './query.py'
python3 './dbs_check.py'
cp -r /tfm_uc3m/data/logs/update_database.log /tfm_uc3m_data/logs/update_database.log
cp -r /tfm_uc3m/data/logs/update_history.log /tfm_uc3m_data/logs/update_history.log
cp -r /tfm_uc3m/data/death.csv /tfm_uc3m_data/death.csv
cp -r /tfm_uc3m/data/pop.csv /tfm_uc3m_data/pop.csv
cd /tfm_uc3m_data
git add ./death.csv
git add ./pop.csv
git add ./logs/update_database.log
git add ./logs/update_history.log
git commit -m "updated database at: $date"
git push https://"$GITHUB_USER":"$GITHUB_TOKEN"@github.com/dreth/tfm_uc3m_data.git
echo "Repo update pushed to GitHub"