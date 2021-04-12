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
project_pop <- function(dataset, year, initial_week, ccaa, age_group, all_ages=FALSE, all_ccaa=FALSE) {
    if (all_ccaa == TRUE) {
        totals <- dataset 
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
