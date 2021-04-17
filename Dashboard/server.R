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
project_pop <- function(dataset, yr, initial_week, ccaas, age_groups, sexes, aggfun=sum, return_ratio=FALSE) {
    #
    if (initial_week == 26) {
        data <- dataset %>% dplyr::filter(year %in% c(yr, yr+1))
    } else {
        data <- dataset %>% dplyr::filter(year == yr)
    }
    
    #
    if (ccaas == 'all') {
        if (age_groups == 'all') {
            if (sexes == 'all') {
                data_t <- data %>% dplyr::filter(sex == 'T')
            } else {
                data_t <- data %>% dplyr::filter(sex == sexes)
            }
        } else {
            if (sexes == 'all') {
                data_t <- data %>% dplyr::filter(sex == 'T' & age_group %in% age_groups)
            } else {
                data_t <- data %>% dplyr::filter(sex == sexes & age_group %in% age_groups)
            }
        }
    } else {
        if (age_groups == 'all') {
            if (sexes == 'all') {
                data_t <- data %>% dplyr::filter(sex == 'T' & ccaa %in% ccaas)
            } else {
                data_t <- data %>% dplyr::filter(sex == sexes & ccaa %in% ccaas)
            }
        } else {
            if (sexes == 'all') {
                data_t <- data %>% dplyr::filter(sex == 'T' & age_group %in% age_groups & ccaa %in% ccaas)
            } else {
                data_t <- data %>% dplyr::filter(sex == sexes & age_group %in% age_groups & ccaa %in% ccaas)
            }
        }   
    }
    # Aggregate
    data <- aggregate(data_t$pop, list(year = data_t$year, week = data_t$week), FUN=aggfun)
    print(data)
    # 
    tryCatch({
        if (initial_week == 26) {
            initial_pop <- data[data$year == yr & data$week == initial_week,'x']
            final_pop <- data[data$year == yr+1 & data$week == 1,'x']
            pop_inbetween <- seq(initial_pop, final_pop, length.out = 27)[2:27]
            ratio_inbetween <- sapply(pop_inbetween, function(x) {x/initial_pop})
        } else {
            initial_pop <- data[data$year == yr & data$week == initial_week,'x']
            final_pop <- data[data$year == yr & data$week == 26,'x']
            pop_inbetween <- seq(initial_pop, final_pop, length.out = 26)
            ratio_inbetween <- sapply(pop_inbetween, function(x) {x/initial_pop})
        }
        # returning ratios or population values for the specified week range
        if (return_ratio == TRUE) {
            return(ratio_inbetween)
        } else {
            return(pop_inbetween)
        }
    }, error = function(cond) {
        new_yr = ifelse(initial_week == 26, yr, yr-1)
        new_initial_week = ifelse(initial_week == 26, 1, 26)
        return(project_pop(dataset=dataset, yr=new_yr, initial_week=new_initial_week, ccaas=ccaas, age_groups=age_groups, sexes=sexes, aggfun=aggfun, return_ratio=TRUE))
    })
}

project_pop(pop, yr=2020, initial_week=26, ccaas='ES11', age_groups='Y10-14', sexes='M')

# SERVER
shinyServer(
    function(input, output, session) {
        
    }
)
