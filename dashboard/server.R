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
    # initialize number of deaths
    death_num <- 0
    
    # cumulative deaths
    numerator <- death %>% dplyr::filter(year %in% yr & week %in% 1:wk & ccaa %in% ccaas & age %in% age_groups & sex == sexes)

    numerator <- aggregate(numerator$death, list(year = numerator$year, week = numerator$week), FUN=sum)
    death_num <- sum(numerator$x)

    # pop for week wk
    period_pop <- pop %>% dplyr::filter(year %in% yr & week == wk & sex == sexes & age_group %in% age_groups & ccaa %in% ccaas)

    period_pop <- aggregate(period_pop$pop, list(year = period_pop$year, week = period_pop$week), FUN=sum)
    ratio <- death_num / sum(period_pop$x)
    
    return(ratio)
} 

TMA_C <- function(ccaas, age_groups, sexes, all=FALSE, sel_week=FALSE) {
    yrs <- 2010:2019
    if (all == TRUE) {
        all_weeks <- list()
        for (i in 1:52) {
            all_weeks[[i]] <- mean(sapply(yrs, function(y) TMA(wk=i, yr=y, ccaas=ccaas, age_groups=age_groups, sexes=sexes)))
        }
        return(all_weeks)
    } else {
        med_tma_wk <- mean(sapply(yrs, function(y) TMA(wk=sel_week, yr=y, ccaas=ccaas, age_groups=age_groups, sexes=sexes)))
        last_tma_wk <- mean(sapply(yrs, function(y) TMA(wk=52, yr=y, ccaas=ccaas, age_groups=age_groups, sexes=sexes)))
        return(c(med_tma_wk, last_tma_wk))
    }
}

# Tasa de mortalidad relativa acumulada
TMRA <- function(wk, yr, ccaas, age_groups, sexes, tma_c=FALSE) {    
    if (length(tma_c) > 1) {
        wks <- c()
        yrs <- c()
        tmras <- c()
        for (i in yr) {
            for (j in wk) {
                yrs <- c(yrs, i)
                wks <- c(wks, j)
                tmras <- c(tmras, (TMA(wk=j, yr=i, ccaas=ccaas, age_groups=age_groups, sexes=sexes)-tma_c[[j]])/tma_c[[52]])
            }
        }
        tmra_df <- data.frame(week=wks, year=yrs, tmra=tmras)
        tmra_df$year <- as.factor(tmra_df$year)
        return(tmra_df)
            
    } else {
        tma <- TMA(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
        tma_c <- TMA_C(sel_week=wk, all=FALSE, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
        return((tma - tma_c[1])/tma_c[2])
    }
}

# Factor de mejora acumulado
FMA <- function(wk, yr, ccaas, age_groups, sexes) {
    tma_1 <- TMA(wk=wk, yr=yr-1, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    tma <- TMA(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    end_tma <- TMA(wk=52, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    return((tma_1-tma)/end_tma)
}

wks <- c()
yrs <- c()
tmras <- c()
for (i in 2011:2020) {
    for (j in 1:52) {
        yrs <- c(yrs, i)
        wks <- c(wks, j)
        tmras <- c(tmras, FMA(wk=j, yr=i, ccaas=CCAA, age_groups=AGE_GROUPS, sexes='T'))
    }
}
tmra_df <- data.frame(week=wks, year=yrs, tmra=tmras)
tmra_df$year <- as.factor(tmra_df$year)
plt <- ggplot(data=tmra_df %>% dplyr::filter(year %in% 2015:2020), aes(x=week, y=tmra)) + geom_line(aes(colour=year))
ggsave('plt.png', plt)


tma_c <- TMA_C(CCAA, AGE_GROUPS, 'T', all=TRUE, sel_week=FALSE)
tmras <- TMRA(wk=1:52, yr=2010:2020, ccaas=CCAA, age_groups=AGE_GROUPS, sexes='T', tma_c=tma_c)
plt <- ggplot(data=tmras %>% dplyr::filter(year %in% 2015:2020), aes(x=week, y=tmra)) + geom_line(aes(colour=year))
ggsave('plt.png', plt)

tmras$year <- as.factor(tmras$year)
ggplot(data=tmras %>% dplyr::filter(year %in% 2015:2019), aes(x=week, y=tmra)) + geom_line(aes(colour=year))


project_pop(dataset=pop, yr=2020, initial_week=26, ccaas=c('ES11','ES53'), age_groups='Y80-84', sexes='M')

# SERVER
shinyServer(
    function(input, output, session) {
        
    } 
)



