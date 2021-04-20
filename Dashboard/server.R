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

# REUSABLE METRICS
# years in pop dataset
years_pop <- unique(pop$year)

# USEFUL FUNCTIONS
# project weekly population
project_pop <- function(dataset, yr, initial_week, ccaas, age_groups, sexes, aggfun=sum, return_ratio=FALSE) {
    #
    if (initial_week == 26) {
        data <- dataset %>% dplyr::filter(year %in% c(yr, yr+1))
    } else {
        data <- dataset %>% dplyr::filter(year == yr)
    }
    
    # Creating filtered dataset
    data_t <- data %>% dplyr::filter(sex == sexes & age_group %in% age_groups & ccaa %in% ccaas)
    # Aggregate
    data <- aggregate(data_t$pop, list(year = data_t$year, week = data_t$week), FUN=aggfun)
    # 
    tryCatch({
        if (initial_week == 26) {
            initial_pop <- data[data$year == yr & data$week == initial_week,'x']
            final_pop <- data[data$year == yr+1 & data$week == 1,'x']
            pop_inbetween <- seq(initial_pop, final_pop, length.out = 26)
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

# RATIOS
# Tasa de mortalidad acumulada
TMA <- function(wk, yr, ccaas, age_groups, sexes) {
    death_num <- 0
    for (i in 1:wk) {
        numerator <- death %>% dplyr::filter(year == yr & week == i & ccaa %in% ccaas & age %in% age_groups & sex == sexes)
        numerator <- aggregate(numerator$death, list(year = numerator$year, week = numerator$week), FUN=sum)
        death_num <- death_num + numerator$x
    }
    
    if (wk != 26 & wk != 1) {
        initial_week <- ifelse(wk > 26, 26, 1)
        selected_wk <- ifelse(wk > 26, wk - 26, wk)
        pop_num <- project_pop(dataset=pop, yr=yr, initial_week=initial_week, ccaas=ccaas, age_groups=age_groups, sexes=sexes)[selected_wk]
        if (pop_num[1] == 1) {
            start_period_pop <- pop %>% dplyr::filter(year == yr & week == wk & sex == sexes & age_group %in% age_groups & ccaa %in% ccaas)
            start_period_pop <- aggregate(start_period_pop$pop, list(year = start_period_pop$year, week = start_period_pop$week), FUN=sum)
            selected_wk <- ifelse(wk > 26, wk - 26, wk)
            pop_num <- (start_period_pop$x * pop_num)[selected_wk]
        }
    } else {
        start_period_pop <- pop %>% dplyr::filter(year == yr & week == wk & sex == sexes & age_group %in% age_groups & ccaa %in% ccaas)
        start_period_pop <- aggregate(start_period_pop$pop, list(year = start_period_pop$year, week = start_period_pop$week), FUN=sum)
        pop_num <- start_period_pop$x
    }

    ratio <- death_num / pop_num
    return(ratio)
}

# Tasa de mortalidad relativa acumulada
TMRA <- function(wk, yr, ccaas, age_groups, sexes) {
    tma <- TMA(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    
    med_tma_wk <- c()
    last_tma_wk <- c()
    for (i in 2010:2019) {
        med_tma_wk <- c(med_tma_wk, TMA(wk=wk, yr=i, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
        last_tma_wk <- c(last_tma_wk, TMA(wk=52, yr=i, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
    }

    return((tma - mean(med_tma_wk))/mean(last_tma_wk))
}

# Factor de mejora acumulado
FMA <- function(wk, yr, ccaas, age_groups, sexes) {
    tma_1 <- TMA(wk=wk, yr=yr-1, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    tma <- TMA(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    end_tma <- TMA(wk=52, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    return((tma_1-tma)/end_tma)
}

weeks <- c()
years <- c()
tmras <- c()
for (i in 2010:2019) {
    for (j in 1:52) {
        weeks <- c(weeks, j)
        years <- c(years, i)
        print(j)
        print(i)
        tmras <- c(tmras, TMRA(j, i, CCAA, AGE_GROUPS, 'T'))
        print(tmras)
    }
}
tmra_df <- data.frame(week=weeks, year=years, tmra=tmras)
tmras <- read.csv('./tmras.csv')
tmras <- tmras[2:length(tmras)]

for (i in 2010:2019) {
    line()
}
project_pop(dataset=pop, yr=2020, initial_week=26, ccaas=c('ES11','ES53'), age_groups='Y80-84', sexes='M')

# SERVER
shinyServer(
    function(input, output, session) {
        
    } 
)



