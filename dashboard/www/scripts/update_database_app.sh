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
python3 './eurostat_check.py'