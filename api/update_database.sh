#!/bin/bash
system=$(uname -s)
date=''

if [ $system == 'Darwin' ]
then
  date=$(date -v-1d +%Y-%m-%d)  # MacOS
elif [ $system == 'Linux' ]
then
  date=$(date +%Y-%m-%d -d "1 day ago")  # Linux
else
  echo "System not recognized!" 1>&2
  exit 64
fi

python -m query.py
echo 'commit database up to' $date
git commit -m "Update database ${date}" '../data/*'
git push

