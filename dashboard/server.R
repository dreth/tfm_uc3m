# IMPORTING LIBRARIES
require(shiny)
require(tidyverse)
require(shinythemes)
require(shinydashboard)
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
    period_pop <- pop %>% dplyr::filter(year %in% yr & week == wk & sex == sexes & age_group %in% age_groups & ccaa %in% ccaas)

    # assuming multiple years+weeks
    if (length(wk) > 1 | length(yr) > 1) {
        period_pop <- aggregate(period_pop$pop, list(year = period_pop$year), FUN=sum)
        if (cmr_c==TRUE) {
            ratio <- mean(death_num / period_pop$x)
        } else {
            ratio <- death_num / period_pop$x
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

# Betterness factor (cumulative)
BF <- function(wk, yr, ccaas, age_groups, sexes) {
    cmr_1 <- CMR(wk=wk, yr=yr-1, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    cmr <- CMR(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    end_cmr <- CMR(wk=52, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    return((cmr_1-cmr)/end_cmr)
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
    
    # Loop for betterness factor
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
    } else if (type == 'deaths') {
        result <- death %>% dplyr::filter(year %in% yr & week %in% wk & ccaa %in% ccaas & age %in% age_groups & sex == sexes)
        result <- aggregate(result, list(year = result$year, week = result$week), FUN=sum)
    }
    
    # returning the dataframe after converting the years to factor (for plots)
    result$year <- as.factor(result$year)
    return(result)
}

# PLOTTING FUNCTIONS
# mortality plots
plot_mortality <- function(df, week_range, yr_range, type='crmr') {
    plt <- ggplot(data=df %>% dplyr::filter(year %in% yr_range & week %in% week_range), aes_string(x='week', y=type)) + geom_line(aes(colour=year)) +
    ggtitle(
        switch(type,
            'crmr'='Cumulative Relativel Mortality Rate',
            'cmr'='Cumulative Mortality Rate',
            'bf'='Cumulative Improvement Factor'
        ))
    return(plt)
}


# SERVER
shinyServer(
    function(input, output, session) {
        # PLOT OUTPUTS
        # Mortality ratio plots
        output$mortalityPlot <- renderPlot({
            df <- factors_df(
                wk=WEEK, 
                yr=YEAR, 
                ccaas=input$selectCCAAMortality,
                age_groups=input$selectAgeMortality,
                sexes=input$selectSexesMortality,
                type=input$plotTypeMortality
            )
            plot_mortality(
                df=df,
                week_range=input$weekSliderSelectorMortality,
                yr_range=input$yearSliderSelectorMortality,
                type=input$plotTypeMortality
            )
        })
    } 
)

