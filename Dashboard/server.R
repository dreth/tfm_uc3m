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

# SERVER
shinyServer(
    function(input, output, session) {
        
    }
)