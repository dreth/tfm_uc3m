#!/bin/bash
cd /home
git clone https://github.com/dreth/tfm_uc3m.git
cd ./tfm_uc3m
ls
cd ./dashboard
R -e "shiny::runApp(host = '0.0.0.0', port = 3838, launch.browser=FALSE)"