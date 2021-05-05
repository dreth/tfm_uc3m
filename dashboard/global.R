# IMPORTING LIBRARIES
require(tidyverse)
require(shinythemes)
require(dplyr)
require(ggplot2)
require(stringr)
require(PerformanceAnalytics)
require(foreach)
require(MASS)
require(gridExtra)
require(plotly)

# TRACE 
options(shiny.trace=TRUE)

# DATASETS
pop = read.csv('https://raw.githubusercontent.com/dreth/tfm_uc3m/main/data/pop.csv')
death = read.csv('https://raw.githubusercontent.com/dreth/tfm_uc3m/main/data/death.csv')

# OPTION LISTS
# CCAAs
CCAA <- unique(pop$ccaa)
names(CCAA) <- c("Galicia","Principado de Asturias","Cantabria","País Vasco","Comunidad Floral de Navarra","La Rioja","Aragón","Comunidad de Madrid","Castilla y León","Castilla-la Mancha","Extremadura","Cataluña","Comunitat Valenciana","Illes Balears","Andalucía","Región de Murcia","Ciudad de Ceuta","Ciudad de Melilla","Canarias")
# AGE GROUPS
AGE_GROUPS <- c("Y_LT5","Y10-14","Y15-19","Y20-24","Y25-29","Y30-34","Y35-39","Y40-44","Y45-49","Y5-9","Y50-54","Y55-59","Y60-64","Y65-69","Y70-74","Y75-79","Y80-84","Y85-89","Y_GE90")
names(AGE_GROUPS) <- c('Less than 5 years old', 'From 10 to 14 years old', 'From 15 to 19 years old', 'From 20 to 24 years old', 'From 25 to 29 years old', 'From 30 to 34 years old', 'From 35 to 39 years old', 'From 40 to 44 years old', 'From 45 to 49 years old', 'From 5 to 9 years old', 'From 50 to 54 years old', 'From 55 to 59 years old', 'From 60 to 64 years old', 'From 65 to 69 years old', 'From 70 to 74 years old', 'From 75 to 79 years old', 'From 80 to 84 years old', 'From 85 to 89 years old', '90+ years old')
# SEXES
SEXES <- c("F","M","T")
names(SEXES) <- c("Females","Males","Total")
# OPTIONS TO PLOT
MORTALITY_PLOT_TYPE <- c("em", "cmr", "crmr", "bf")
names(MORTALITY_PLOT_TYPE) <- c('Excess Mortality','Cumulative mortality rate', 'Cumulative relative mortality rate', 'Cumulative improvement factor')
# DATE
YEAR <- unique(pop$year)
WEEK <- unique(death$week)
# CCAA UI SELECTOR
CCAA_UI_SELECT <- c('all', 'select')
names(CCAA_UI_SELECT) <- c('All CCAAs', 'Select CCAAs')
# AGE GROUP UI SELECTOR
AGE_GROUPS_UI_SELECT <- c('all', 'select')
names(AGE_GROUPS_UI_SELECT) <- c('All Age groups', 'Select Age groups')
