# IMPORTING LIBRARIES
require(shiny)
require(tidyverse)
require(shinythemes)
library(shinydashboard)
require(dplyr)
require(ggplot2)
require(stringr)
require(PerformanceAnalytics)
require(foreach)
require(MASS)
require(gridExtra)
require(plotly)

# DATASETS
pop = read.csv('https://raw.githubusercontent.com/dreth/tfm_uc3m/main/data/pop.csv')
death = read.csv('https://raw.githubusercontent.com/dreth/tfm_uc3m/main/data/death.csv')

# USEFUL FUNCTIONS
# project weekly population
project_pop <- function(dataset, year, initial_week, ccaa, age_group, sex, aggfun=sum) {
    data <- dataset
    if (ccaa == 'all') {
        if (age_group == 'all') {
            if (sex == 'all') {
                data_t <- data[data$sex == 'T',]
                data <- aggregate(data_t$pop, list(year = data_t$year, week = data_t$week), FUN=aggfun)
            } else {
                data_t <- data[data$sex == sex,]
                data <- aggregate(data_t$pop, list(year = data_t$year, week = data_t$week), FUN=aggfun)
            }
        } else {
            if (sex == 'all') {
                data_t <- data[data$age_group == age_group & data$sex == 'T',]
                data <- aggregate(data_t$pop, list(year = data_t$year, week = data_t$week), FUN=aggfun)
            } else {
                data_t <- data[data$age_group == age_group & data$sex == sex,]
                data <- aggregate(data_t$pop, list(year = data_t$year, week = data_t$week), FUN=aggfun)
            }
        }
        
        
    }
    initial_pop <- dataset %>% 
    final_pop <- 
    pop_inbetween <- seq(0, 1, length.out = 26)
    ratio_inbetween <- sapply(pop_inbetween, function(x) {x/initial_pop})
}

# SERVER
shinyServer(
    function(input, output, session) {
        
    }
)
