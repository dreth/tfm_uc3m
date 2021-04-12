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
project_pop <- function(dataset, year, initial_week, ccaa, age_group, total=FALSE, all_ccaa=FALSE) {
    initial_pop %>% filter()
    final_pop %>%
    pop_inbetween <- seq(0, 1, length.out = 10)
}

# SERVER
shinyServer(
    function(input, output, session) {
        
    }
)
