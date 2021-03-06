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
require(MASS)
require(plotly)
require(leaflet)
require(rgdal)
require(RColorBrewer)
require(zoo)
require(Rcpp)
require(RcppRoll)

# Running last eurostat update check
system('bash ./www/scripts/check_dbs.sh', wait=FALSE)

# TRACE 
options(shiny.trace=FALSE)

# DIAGNOSTIC FEATURES ENABLE/DISABLE
death_count <- FALSE

# DATASETS
pop <- read.csv('../data/pop.csv')
death <- read.csv('../data/death.csv')
# Removing X-column imported from read.csv
pop <- pop[,2:length(pop)]
death <- death[,2:length(death)]
# Original IDs for reference
EurostatDBID <- 'demo_r_mwk2_05'
INEDBID <- '9681'
# Maximum week for the latest year
MAX_WEEK <- max(death[death$year == as.numeric(format(Sys.time(),'%Y')),'week'])
# determine if app is running inside of a container
ISDOCKER <- ifelse(system('cat /isdocker', intern=TRUE)=="True", TRUE, FALSE)

# OPTION LISTS
# CCAAs
CCAA <- unique(pop$ccaa)
names(CCAA) <- c("Galicia","Principado de Asturias","Cantabria","País Vasco","Comunidad Floral de Navarra","La Rioja","Aragón","Comunidad de Madrid","Castilla y León","Castilla-la Mancha","Extremadura","Cataluña","Comunitat Valenciana","Illes Balears","Andalucía","Región de Murcia","Ciudad de Ceuta","Ciudad de Melilla","Canarias")
CCAA_SHORT <- c("Galicia", "Asturias", "Cantabria", "Euskadi", "Navarra", "La Rioja", "Aragón", "Madrid", "Castilla y León", "Castilla-la Mancha", "Extremadura", "Cataluña", "Valencia", "Baleares", "Andalucía", "Murcia", "Ceuta", "Melilla", "Canarias")
names(CCAA_SHORT) <- CCAA
# AGE GROUPS
AGE_GROUPS <- c("Y_LT5","Y5-9","Y10-14","Y15-19","Y20-24","Y25-29","Y30-34","Y35-39","Y40-44","Y45-49","Y50-54","Y55-59","Y60-64","Y65-69","Y70-74","Y75-79","Y80-84","Y85-89","Y_GE90")
names(AGE_GROUPS) <- c('Less than 5 years old', 'From 5 to 9 years old', 'From 10 to 14 years old', 'From 15 to 19 years old', 'From 20 to 24 years old', 'From 25 to 29 years old', 'From 30 to 34 years old', 'From 35 to 39 years old', 'From 40 to 44 years old', 'From 45 to 49 years old', 'From 50 to 54 years old', 'From 55 to 59 years old', 'From 60 to 64 years old', 'From 65 to 69 years old', 'From 70 to 74 years old', 'From 75 to 79 years old', 'From 80 to 84 years old', 'From 85 to 89 years old', '90+ years old')
AGE_GROUP_RANGES <- c("<5","5-9","10-14","15-19","20-24","25-29","30-34","35-39","40-44","45-49","50-54","55-59","60-64","65-69","70-74","75-79","80-84","85-89","90+")
names(AGE_GROUP_RANGES) <- AGE_GROUPS
# SEXES
SEXES <- c("F","M","T")
names(SEXES) <- c("Females","Males","Total")
# OPTIONS TO PLOT (MORTALITY)
MORTALITY_PLOT_TYPE <-switch(as.character(death_count), 'TRUE'=c("em", "cmr", "crmr", "mif", "dc"), 'FALSE'=c("em", "cmr", "crmr", "mif"))
names(MORTALITY_PLOT_TYPE) <-switch(as.character(death_count), 'TRUE'=c('Excess Mortality','Cumulative mortality rate', 'Cumulative relative mortality rate', 'Cumulative improvement factor', 'Death count'), 'FALSE'=c('Excess Mortality','Cumulative mortality rate', 'Cumulative relative mortality rate', 'Cumulative improvement factor'))
# reverse options for reference
MORTALITY_PLOT_TYPE_R <- names(MORTALITY_PLOT_TYPE)
names(MORTALITY_PLOT_TYPE_R) <- MORTALITY_PLOT_TYPE
# OPTIONS TO PLOT (MAPS)
MAPS_PLOT_TYPE <-switch(as.character(death_count), 'TRUE'=c("em", "cmr", "crmr", "mif", "le", "dc"), 'FALSE'=c("em", "cmr", "crmr", "mif", "le"))
names(MAPS_PLOT_TYPE) <-switch(as.character(death_count), 'TRUE'=c('Excess Mortality','Cumulative mortality rate', 'Cumulative relative mortality rate', 'Cumulative improvement factor', 'Life expectancy', 'Death count'), 'FALSE'=c('Excess Mortality','Cumulative mortality rate', 'Cumulative relative mortality rate', 'Cumulative improvement factor', 'Life expectancy'))
# reverse options for reference
MAPS_PLOT_TYPE_R <- names(MAPS_PLOT_TYPE)
names(MAPS_PLOT_TYPE_R) <- MAPS_PLOT_TYPE
# DATE
YEAR <- unique(pop$year)
WEEK <- unique(death$week)
# CCAA UI SELECTOR
CCAA_UI_SELECT <- c('all', 'select')
names(CCAA_UI_SELECT) <- c('All CCAAs', 'Select CCAAs')
# AGE GROUP UI SELECTOR
AGE_GROUPS_UI_SELECT <- c('all', 'select')
names(AGE_GROUPS_UI_SELECT) <- c('All Age groups', 'Select Age groups')
# AGE GROUP UI SELECTOR (LIFE EXP)
AGE_GROUPS_UI_SELECT_LE <- c('at_birth', 'select')
names(AGE_GROUPS_UI_SELECT_LE) <- c('Life expectancy at birth', 'Select Age group')
# SHOW PLOT OR LIFE TABLES (LIFE EXP)
SHOW_PLOT_OR_LT <- c('plot','life_table')
names(SHOW_PLOT_OR_LT) <- c('Life expectancy time series', 'Life table')
# PLOTTING DEVICE TO USE
PLOT_DEVICE_UI_SELECT <- c('ggplot2','plotly')
names(PLOT_DEVICE_UI_SELECT) <- c('Static (ggplot2)', 'Interactive (plotly)')
# DATABASE TABLES
DATABASE_TABLES <- c('death','pop')
names(DATABASE_TABLES) <- c('Deaths table', 'Population table')
# PLOT DOWNLOAD SIZE SELECTOR
DOWNLOAD_SIZE_TOGGLE <- c('predefined','custom')
names(DOWNLOAD_SIZE_TOGGLE) <- c('Predefined','Custom')
# PLOT DOWNLOAD SIZE PREDEFINED SELECTOR
DOWNLOAD_SIZE_PREDEF <- c(200,500,800,1200,2000)
names(DOWNLOAD_SIZE_PREDEF) <- c('200x200','500x500','800x800','1200x1200','2000x2000')
# PLOT DOWNLOAD IMAGE FORMATS
DOWNLOAD_IMAGE_FORMAT <- c('png','jpeg','pdf','bmp','tiff','tex','eps')
# MAP PLOT LIBRARY SELECTOR
PLOT_LIBRARY_MAPS <- c('ggplot2','leaflet')
names(PLOT_LIBRARY_MAPS) <- c('Static (ggplot2)', 'Interactive (leaflet)')
# SECTION SELECTOR FOR DOCS
SECTIONS <- c('mortality','maps','lifeExp','dbTables','dbInfo')
names(SECTIONS) <- c('Mortality', 'Maps', 'Life expectancy', 'Database tables', 'Database information and update')
# LIFE TABLE/PLOT BUTTON LABEL
LIFEBUTTON <- ''

# DATABASE VECTOR
# contains databases indexed by string
DBs <- list(death=death, pop=pop)

# REUSABLE METRICS
# years in pop dataset
years_pop <- unique(pop$year)

# MAPS CCAA INDEX
# MAP FOR LEAFLET
# reading map shapefile
esp_leaflet <- readOGR(dsn = './www/maps/map_shapefiles', encoding='UTF-8')
# creating index for CCAAs
esp_leaflet@data$ccaa <- c("ES7","ES61","ES24","ES12","ES53","ES13","ES41","ES42","ES51","ES52","ES43","ES11","ES3","ES62","ES22","ES21","ES23","ES63","ES64")
# CCAAs codes' order as they show in the shapefile
esp_leaflet@data$id <- c(18, 14, 6, 1, 13, 2, 8, 9, 11, 12, 10, 0, 7, 15, 4, 3, 5, 16, 17)

# MAP FOR GGPLOT
# reading map shapefile
esp_ggplot <- readOGR(dsn = './www/maps/map_shapefiles_ggplot', encoding='UTF-8')
# creating index for CCAAs
esp_ggplot@data$ccaa <- c("ES7","ES61","ES24","ES12","ES53","ES13","ES41","ES42","ES51","ES52","ES43","ES11","ES3","ES62","ES22","ES21","ES23","ES63","ES64",NA)
# CCAAs codes' order as they show in the shapefile
esp_ggplot@data$id <- c(18, 14, 6, 1, 13, 2, 8, 9, 11, 12, 10, 0, 7, 15, 4, 3, 5, 16, 17, NA)

# SIGNIFICANT FIGURES FOR EACH METRIC
SIG_FIGURES <- function(m) {switch(m, "em"=2, "cmr"=3, "crmr"=10, "mif"=10, "dc"=2)}

# MEASURES AND RATIOS
# Cumulative mortality rate
CMR <- function(wk, yr, ccaas, age_groups, sexes, cmr_c=FALSE) {
    # initialize number of deaths
    death_num <- 0

    # assuming multiple years
    # cumulative deaths
    numerator <- death %>% dplyr::filter(year %in% yr & week %in% 1:wk & ccaa %in% ccaas & age %in% age_groups & sex == sexes)

    if (length(yr) > 1) {
        # multiple years
        numerator <- aggregate(numerator$death, list(year = numerator$year), FUN=sum)
        death_num <- numerator$x
    } else {
        # individual years+weeks
        numerator <- aggregate(numerator$death, list(year = numerator$year, week = numerator$week), FUN=sum)
        death_num <- sum(numerator$x)
    }    
    
    # pop for week wk
    period_pop <- pop %>% dplyr::filter(year %in% yr & week == wk & sex == sexes & age %in% age_groups & ccaa %in% ccaas)

    # assuming multiple years
    if (length(yr) > 1) {
        # multiple years
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
        med_cmr_wk <- mean(CMR(wk=sel_week, yr=yrs, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
        last_cmr_wk <- mean(CMR(wk=52, yr=yrs, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
        return(c(med_cmr_wk, last_cmr_wk))
    }
}

# Cumulative relative mortality rate
CRMR <- function(wk, yr, ccaas, age_groups, sexes, all=FALSE, cmr_c_yrs=2010:2019) {    
    cmr <- CMR(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    cmr_c <- CMR_C(sel_week=wk, all=all, ccaas=ccaas, age_groups=age_groups, sexes=sexes, yrs=cmr_c_yrs)
    return((cmr - cmr_c[1])/cmr_c[2])
}

# Improvement factor (cumulative)
MIF <- function(wk, yr, ccaas, age_groups, sexes) {
    cmr_1 <- CMR(wk=wk, yr=yr-1, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    cmr <- CMR(wk=wk, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
    end_cmr <- CMR(wk=52, yr=yr-1, ccaas=ccaas, age_groups=age_groups, sexes=sexes)
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
        # isolating 2021, as it is still within the COVID-19 pandemic period
        agg[agg$year >= 2021 & agg$year <= 2027,'ma'] <- agg[agg$year == 2020,'ma']
        # appending results to df
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

# Death count
DC <- function(wk, yr, ccaas, age_groups, sexes) {
    # If more than one year is desired to be calculated
    if (length(yr) > 1) {
        # Filtering and aggregating the dataframe
        filtered <- death %>% dplyr::filter(year %in% yr & week == wk & ccaa %in% ccaas & age %in% age_groups & sex == sexes)
        agg <- aggregate(filtered$death, list(year = filtered$year), FUN=sum)

        # If a year is incomplete, add a NA, to avoid plotting a straight line
        if (length(agg[agg$year %in% yr,'x']) < length(yr)) {
            agg <- rbind(agg, data.frame(year=max(yr), x=NA))
        }

        # appending results to df
        return(agg$x)

    # If only a single value is desired to be calculated
    } else {
        # Filtering and aggregating the dataframe
        filtered <- death %>% dplyr::filter(year %in% yr & week == wk & ccaa %in% ccaas & age %in% age_groups & sex == sexes)
        agg <- aggregate(filtered$death, list(year = filtered$year), FUN=sum)

        # If year is incomplete, return NA
        if (agg[length(agg$x), 'year'] != yr) {
            return(NA)
        } else {
            return(agg$x)
        }
    }
}

# DATAFRAME GENERATING FUNCTIONS
# historical cmr, crmr, mif, em and le
factors_df <- function(wk, yr, ccaas, age_groups, sexes, type='crmr', cmr_c_yrs=2010:max(YEAR)-1) {
    # Initializing vectors for the df
    wks <- c()
    yrs <- c()
    metric <- c()

    # Cumulative relative mortality rate
    if (type == 'crmr') {
        cmr_c <- CMR_C(ccaas=ccaas, age_groups=age_groups, sexes=sexes, all=TRUE, sel_week=FALSE, yrs=cmr_c_yrs)
        for (j in wk) {
            yrs <- c(yrs, yr)
            wks <- c(wks, rep(j,length(yr)))
            metric <- c(metric, (CMR(wk=j, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes)-cmr_c[[j]])/cmr_c[[52]])
        }
        result <- data.frame(week=wks, year=yrs, crmr=metric)
    
    # Improvement factor
    } else if (type == 'mif') {
        if (min(yr) < 2011) {
            result <- c('error', 'The lower bound for year must be greater than or equal to 2011')
        } else {
            for (j in wk) {
                yrs <- c(yrs, yr)
                wks <- c(wks, rep(j,length(yr)))
                metric <- c(metric, MIF(wk=j, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
            }
            result <- data.frame(week=wks, year=yrs, mif=metric)
        }
    
    # Cumulative mortality rate
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

    # Death count
    } else if (type == 'dc') {
        for (j in wk) {
            yrs <- c(yrs, yr)
            wks <- c(wks, rep(j,length(yr)))
            metric <- c(metric, DC(wk=j, yr=yr, ccaas=ccaas, age_groups=age_groups, sexes=sexes))
        }
        result <- data.frame(week=wks, year=yrs, dc=metric)
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

# %% LIFE EXPECTANCY FUNCTIONS
# CRUDE MORTALITY RATE FUNCTION (PROBABILITY OF DEATH)
MR <- function(wk, yr, ccaas, sexes) {
    # assuming multiple years
    # deaths
    numerator <- death %>% dplyr::filter(year %in% (min(yr)-1):max(yr) & ccaa %in% ccaas & sex == sexes)

    # deaths rolling window of 1 year for year(s) yr and week wk
    numerator <- aggregate(numerator$death, list(year = numerator$year, week = numerator$week, age = numerator$age), FUN=sum)
    numerator$age <- factor(numerator$age, levels=AGE_GROUPS)
    numerator$year <- factor(numerator$year)
    numerator <- numerator[order(numerator$year, numerator$age),]
    numerator$rolling_sum <- NA
    for (ag in AGE_GROUPS) {
        numerator[numerator$age == ag,'rolling_sum'] = lag(roll_sum(numerator[numerator$age == ag,'x'], 52, fill=NA),26)
    }
    numerator <- numerator %>% dplyr::filter(week %in% wk & year %in% yr)
    numerator <- numerator$rolling_sum

    # Population at week wk
    denominator <- pop %>% dplyr::filter(year %in% yr & sex == sexes & ccaa %in% ccaas)
    denominator <- aggregate(denominator$pop, list(year = denominator$year, week = denominator$week, age = denominator$age), FUN=sum)
    denominator$age <- factor(denominator$age, levels=AGE_GROUPS)
    denominator$year <- factor(denominator$year)
    denominator <- denominator[order(denominator$year, denominator$age),]
    denominator <- denominator %>% dplyr::filter(week %in% wk & year %in% yr)

    # mortality rate for life table
    nmx <- numerator/denominator$x
    
    # creating levels for age groups
    df <- data.frame(year=denominator$year, week=denominator$week, age=denominator$age, nmx=nmx)

    # resulting crude mortality rate
    return(df)
}

# LIFE TABLE FUNCTION
LT <- function(wk, yr, ccaas, sexes, initial_pop=1e5, age_interval_lengths=5) {
    # creating the life table template
    df <- MR(wk=wk, yr=yr, ccaas=ccaas, sexes=sexes)
    for (col in c("nqx","lx","ndx", "nLx", "Tx", "ex")) {df[,col] = rep(NA,length(df[,'week']))}
    df$nqx <- NA
    for (i in 1:length(df$nmx)) {
        if (df$age[i] == 'Y_GE90') {
            df$nqx[i] <- 1
        } else {
            df$nqx[i] <- 1 - exp(-age_interval_lengths * df$nmx[i])
        }
    }

    # creating the lx col
    for (year in yr) {
        for (week in wk) {
            # obtaining the death rates for year and week in loop
            nqx <- df[df$year == year & df$week == week,'nqx']
            nmx <- df[df$year == year & df$week == week,'nmx']
            if (length(nqx) == 0) {
                nqx <- rep(NA,length(AGE_GROUPS))
                nmx <- rep(NA,length(AGE_GROUPS))
            }

            # creating all metrics
            lx <- c(initial_pop)
            for (i in 2:length(nqx)) { lx[i] <- lx[i-1]*(1-nqx[i-1]) }
            ndx <- lx*nqx
            nLx <- ndx/nmx
            Tx <- sapply(1:length(nLx), function(s) {sum(nLx[s:length(nLx)])})
            ex <- Tx/lx

            # adding the columns to the df
            df[df$year == year & df$week == week,'lx'] <- lx
            df[df$year == year & df$week == week,'ndx'] <- ndx
            df[df$year == year & df$week == week,'nLx'] <- nLx
            df[df$year == year & df$week == week,'Tx'] <- Tx
            df[df$year == year & df$week == week,'ex'] <- ex
        }
    }
    return(df)
}
 
# GENERATE MAP DATA
gen_map_data <- function(wk, yr, age_groups, sexes, metric, shape_data=esp_leaflet) {
    # functions vector with name
    fns <- c(CMR, CRMR, MIF, EM, DC, LT)
    names(fns) <- c('cmr','crmr','mif','em','dc','le')
    
    # iterating over ccaas to calculate indexes for selected data
    shape_data@data$metric <- NA
    for (i in 1:length(shape_data@data$ccaa)) {
        shape_data@data[i,'metric'] = tryCatch(
            {
                if (metric != 'le') {
                    fns[[metric]](wk=wk, yr=yr, ccaas=shape_data@data$ccaa[i], age_groups=age_groups, sexes=sexes)
                } else {
                    lt <- LT(wk=wk, yr=yr, ccaas=shape_data@data$ccaa[i], sexes=sexes)
                    lt <- lt[lt$age == age_groups,'ex']
                }   
            },
            error=function(e) {NA}
        )
    }
    # returning the data
    return(shape_data)
}

# GENERATE MAP
gen_choropleth <- function(dataset, metric, wk, yr, library='leaflet', leaflet_provider="CartoDB.DarkMatterNoLabels", palette="Reds") {
    # USING LEAFLET
    if (library == 'leaflet') {
        # colours
        pal <- colorNumeric(palette=palette, domain = dataset$metric)

        # pop up with data
        metric_name <- MAPS_PLOT_TYPE_R[metric]
        popup <- paste("<strong>CCAA:</strong>",CCAA_SHORT[dataset$ccaa],str_interp("<br><strong>${metric_name}:</strong>"),round(dataset$metric,5))

        # creating map
        leaflet(data = dataset,
                options = leafletOptions(zoomControl = FALSE, dragging = FALSE, doubleClickZoom= FALSE)) %>%
            addProviderTiles(leaflet_provider) %>%
            addPolygons(fillColor = ~pal(metric), 
                        fillOpacity = 1, 
                        color = "#000000", 
                        weight = 1,
                        popup = popup) %>%
            addLegend("topleft", 
                    pal = pal, 
                    values = ~metric,
                    title = str_interp("${metric_name}"),
                    opacity = 2)
    } else {
        # fortify dataset and convert id to numeric
        esp_df <- fortify(dataset) %>% mutate(id=as.numeric(id))

        # joining by id and filling using the metric data
        esp_df <- esp_df %>% left_join(dataset@data, by = 'id') %>% fill(metric)

        # plot title
        plotTitle <- str_interp("${MAPS_PLOT_TYPE_R[metric]} for week: ${wk} of year: ${yr}")

        # legend title
        legendTitle <- MAPS_PLOT_TYPE_R[metric]

        # plotting the map
        ggplot() + 
            geom_polygon(data=esp_df, aes(fill=metric, x=long, y=lat, group=group)) + 
            geom_path(data=esp_df, aes(x=long, y=lat, group=group), color='white', size=0.1) + 
            coord_equal() +
            theme_void() + 
            scale_x_continuous(expand=c(0,0.2)) + 
            scale_y_continuous(expand=c(0,0)) + 
            theme(
                legend.position = c(0.7, 0.03),
                legend.text.align = 0,
                legend.text = element_text(size = 14, hjust = 0),
                legend.title = element_text(size = 20),
                plot.title = element_text(size = 20, hjust = 0.8),
                panel.border = element_blank()
            ) +
            labs(fill=legendTitle) +
            ggtitle(plotTitle)
    }
}