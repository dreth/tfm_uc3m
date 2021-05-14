# IMPORTING LIBRARIES
require(shiny)
require(shinydashboard)
require(shinyjs)
require(tidyverse)
require(shinythemes)
require(pracma)
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

# SET PYTHON ENVIRONMENT VARIABLE FOR DATABASE UPDATE
# Sys.setenv(PATH = paste(c("/home/dreth/anaconda3/bin/", Sys.getenv("PATH")), collapse = .Platform$path.sep))

# DATASETS
pop <- read.csv('../data/pop.csv')
death <- read.csv('../data/death.csv')
# Removing X-column imported from read.csv
pop <- pop[,2:length(pop)]
death <- death[,2:length(death)]

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
# PLOTTING DEVICE TO USE
PLOT_DEVICE_UI_SELECT <- c('ggplot2','plotly')
names(PLOT_DEVICE_UI_SELECT) <- c('ggplot2', 'plotly')
# DATABASE TABLES
DATABASE_TABLES <- c('death','pop')
names(DATABASE_TABLES) <- c('Deaths table', 'Population table')

# DATABASE VECTOR
# contains databases indexed by string
DBs <- list(death=death, pop=pop)

# REUSABLE METRICS
# years in pop dataset
years_pop <- unique(pop$year)

# MEASURES AND RATIOS
# Cumulative mortality rate
CMR <- function(wk, yr, ccaas, age_groups, sexes, cmr_c=FALSE) {
    # initialize number of deaths
    death_num <- 0

    # assuming multiple years+weeks
    # cumulative deaths
    numerator <- death %>% dplyr::filter(year %in% yr & week %in% 1:wk & ccaa %in% ccaas & age %in% age_groups & sex == sexes)

    if (length(wk) > 1 | length(yr) > 1) {
        # multiple years+weeks
        numerator <- aggregate(numerator$death, list(year = numerator$year), FUN=sum)
        death_num <- numerator$x
    } else {
        # individual years+weeks
        numerator <- aggregate(numerator$death, list(year = numerator$year, week = numerator$week), FUN=sum)
        death_num <- sum(numerator$x)
    }    
    
    # pop for week wk
    period_pop <- pop %>% dplyr::filter(year %in% yr & week == wk & sex == sexes & age %in% age_groups & ccaa %in% ccaas)

    # assuming multiple years+weeks
    if (length(wk) > 1 | length(yr) > 1) {
        period_pop <- aggregate(period_pop$pop, list(year = period_pop$year), FUN=sum)
        if (cmr_c==TRUE) {
            ratio <- tryCatch(mean(death_num / period_pop$x), warning=function(w) {return(c(mean(death_num[1:length(yr)-1] / period_pop$x[1:length(yr)-1]),NA))})
        } else {
            ratio <- tryCatch(death_num / period_pop$x, warning=function(w) {return(c(death_num[1:length(yr)-1] / period_pop$x[1:length(yr)-1],NA))})
        }
    } else {
    # individual years+weeks
        period_pop <- aggregate(period_pop$pop, list(year = period_pop$year, week = period_pop$week), FUN=sum)
        ratio <- death_num / sum(period_pop$x)
    }
    
    return(ratio)
} 

# Cumulative mortality rate for a group of years (weekly)
CMR_C <- function(ccaas, age_groups, sexes, all=FALSE, sel_week=FALSE, yrs=2010:2019) {
    if (all == TRUE) {
        all_weeks <- list()
        for (i in 1:52) {
            all_weeks[[i]] <- CMR(wk=i, yr=yrs, ccaas=ccaas, age_groups=age_groups, sexes=sexes, cmr_c=TRUE)
        }
        return(all_weeks)
    } else {
        med_cmr_wk <- mean(sapply(yrs, function(y) CMR(wk=sel_week, yr=y, ccaas=ccaas, age_groups=age_groups, sexes=sexes)))
        last_cmr_wk <- mean(sapply(yrs, function(y) CMR(wk=52, yr=y, ccaas=ccaas, age_groups=age_groups, sexes=sexes)))
        return(c(med_cmr_wk, last_cmr_wk))
    }
}

# Cumulative relative mortality rate
CRMR <- function(wk, yr, ccaas, age_groups, sexes, all=FALSE, cmr_c_yrs=2010:2019) {    
    cmr <- CMR(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    cmr_c <- CMR_C(sel_week=wk, all=FALSE, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    return((cmr - cmr_c[1])/cmr_c[2])
}

# Improvement factor (cumulative)
BF <- function(wk, yr, ccaas, age_groups, sexes) {
    cmr_1 <- CMR(wk=wk, yr=yr-1, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    cmr <- CMR(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    end_cmr <- CMR(wk=52, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    return((cmr_1-cmr)/end_cmr)
}

# Excess of mortality
EM <- function(wk, yr, ccaas, age_groups, sexes, ma=5) {
    # If more than one year is desired to be calculated
    if (length(yr) > 1) {
        # Filtering and aggregating the dataframe
        filtered <- death %>% dplyr::filter(year %in% (min(yr)-5):max(yr) & week == wk & ccaa %in% ccaas & age %in% age_groups & sex == sexes)
        agg <- aggregate(filtered$death, list(year = filtered$year), FUN=sum)

        # If a year is incomplete, add a NA, to avoid plotting a straight line
        if (length(agg[agg$year %in% yr,'x']) < length(yr)) {
            agg <- rbind(agg, data.frame(year=max(yr), x=NA))
        }

        # generate moving average with a window of ma to calculate excess mortality
        # and lag it to fit it to the dataframe (as the current year can't be part of the average)
        agg$ma <- lag(movavg(agg$x, ma, type='s'))
        result_df <- agg[agg$year %in% yr,]
        return(result_df$x - result_df$ma)

    # If only a single value is desired to be calculated
    } else {
        # Filtering and aggregating the dataframe
        filtered <- death %>% dplyr::filter(year %in% (yr-5):yr & week == wk & ccaa %in% ccaas & age %in% age_groups & sex == sexes)
        agg <- aggregate(filtered$death, list(year = filtered$year), FUN=sum)

        # If year is incomplete, return NA
        if (agg[length(agg$x), 'year'] != yr) {
            return(NA)
        } else {
            actual <- agg[length(agg$x), 'x']
            expected <- mean(agg[1:(length(agg$x)-1), 'x'])
            return(actual - expected)
        }
    }
}

# DATAFRAME GENERATING FUNCTIONS
# historical cmr, crmr and bf
factors_df <- function(wk, yr, ccaas, age_groups, sexes, type='crmr', cmr_c_yrs=2010:max(YEAR)-1) {
    # Initializing vectors for the df
    wks <- c()
    yrs <- c()
    metric <- c()

    # Loop for cumulative relative mortality rate
    if (type == 'crmr') {
        cmr_c <- CMR_C(ccaas=ccaas, age_groups=age_groups, sexes=sexes, all=TRUE, sel_week=FALSE, yrs=cmr_c_yrs)
        for (j in wk) {
            yrs <- c(yrs, yr)
            wks <- c(wks, rep(j,length(yr)))
            metric <- c(metric, (CMR(wk=j, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)-cmr_c[[j]])/cmr_c[[52]])
        }
        result <- data.frame(week=wks, year=yrs, crmr=metric)
    
    # Loop for improvement factor
    } else if (type == 'bf') {
        for (j in wk) {
            yrs <- c(yrs, yr)
            wks <- c(wks, rep(j,length(yr)))
            metric <- c(metric, BF(wk=j, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
        }
        result <- data.frame(week=wks, year=yrs, bf=metric)
    
    # Loop for cumulative mortality rate
    } else if (type == 'cmr') {
        for (j in wk) {
            yrs <- c(yrs, yr)
            wks <- c(wks, rep(j,length(yr)))
            metric <- c(metric, CMR(wk=j, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
        }
        result <- data.frame(week=wks, year=yrs, cmr=metric)
    
    # Excess mortality
    } else if (type == 'em') {
        # If lower bound is lower than 2015 return an error
        if (min(yr) < 2015) {
            result <- c('error', 'The lower bound for year must be greater than or equal to 2015')
        } else {
            for (j in wk) {
                yrs <- c(yrs, yr)
                wks <- c(wks, rep(j,length(yr)))
                metric <- c(metric, EM(wk=j, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
            }
            result <- data.frame(week=wks, year=yrs, em=metric)
        }
    }
    
    # returning the dataframe after converting the years to factor (for plots)
    if (suppressWarnings({result[1] != 'error'})) {
        result$year <- as.factor(result$year)
    }
    return(result)
}

# Filtering the tables with given params
filter_df_table <- function(db, wk, yr, ccaas, age_groups, sexes) {
    filtered_df <- db %>% dplyr::filter(year %in% yr & week %in% wk & ccaa %in% ccaas & age %in% age_groups & sex %in% sexes)
    return(filtered_df)
}

# OTHER HELPER FUNCTIONS
# Function to read lines and return a paste separated by an html line break
paste_readLines <- function(text) {
    return(paste(readLines(text), collapse='<br/>'))
}