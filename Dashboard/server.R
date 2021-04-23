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

# MEASURES AND RATIOS
# Tasa de mortalidad acumulada
TMA <- function(wk, yr, ccaas, age_groups, sexes) {
    death_num <- 0
    for (i in 1:wk) {
        numerator <- death %>% dplyr::filter(year == yr & week == i & ccaa %in% ccaas & age %in% age_groups & sex == sexes)
        numerator <- aggregate(numerator$death, list(year = numerator$year, week = numerator$week), FUN=sum)
        death_num <- death_num + numerator$x
    }
    
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

tmras$year <- as.factor(tmras$year)
ggplot(data=tmras %>% dplyr::filter(year %in% 2015:2019), aes(x=week, y=tmra)) + geom_line(aes(colour=year))


project_pop(dataset=pop, yr=2020, initial_week=26, ccaas=c('ES11','ES53'), age_groups='Y80-84', sexes='M')

# SERVER
shinyServer(
    function(input, output, session) {
        
    } 
)



