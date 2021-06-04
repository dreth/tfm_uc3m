# SERVER
shinyServer(
    function(input, output, session) {
        # REACTIVE VALUES
        updateDBLogs <- reactiveFileReader(intervalMillis=2000, session=session, filePath='../api/logs/update_database.log', readFunc=paste_readLines)
        updateDBLogsLast <- reactiveFileReader(intervalMillis=4000, session=session, filePath='../api/logs/update_history.log', readFunc=readLines)
        updateEurostatLogsLast <- reactiveFileReader(intervalMillis=4000, session=session, filePath='../api/logs/last_eurostat_update.log', readFunc=readLines)
        updateEurostatLogsEarliestProvisional <- reactiveFileReader(intervalMillis=4000, session=session, filePath='../api/logs/earliest_eurostat_provisional.log', readFunc=readLines)
        updateINELogsLast <- reactiveFileReader(intervalMillis=4000, session=session, filePath='../api/logs/last_ine_update.log', readFunc=readLines)

        # PLOTTING FUNCTIONS
        # mortality plots
        plot_metric <- function(df, week_range, yr_range, type='crmr', device='ggplot2') {
            # plot title construction
            selectedCCAAs <- switch(input$selectCCAAMortalityTotal, all='All', select=CCAA_SHORT[input$selectCCAAMortality])
            selectedAgeGroups <- switch(input$selectAgeGroupsMortalityTotal, all='All', select=AGE_GROUP_RANGES[input$selectAgeMortality])
            print(selectedCCAAs)
            plotTitle <- switch(type,
                                'em'='Excess Mortality',
                                'crmr'='Cumulative Relative Mortality Rate',
                                'cmr'='Cumulative Mortality Rate',
                                'bf'='Cumulative Improvement Factor',
                                'dc'='Death count',
                                'le'='Life expectancy'
                                )
            titleCCAA <- paste(selectedCCAAs,collapse=", ")
            titleAgeGroups <- paste(selectedAgeGroups,collapse=", ")
            plotTitle <- ifelse(type=='le',str_interp('${plotTitle} for CCAA(s): ${titleCCAA}'),str_interp('${plotTitle} for CCAA(s): ${titleCCAA}, and Age Groups: ${titleAgeGroups}'))

            # Condition in case of error
            if (suppressWarnings({df[1] == 'error'})) {
                return(text(x=0.5, y=0.5, col="black", cex=2, df[2]))

            # Condition for when user uses ggplot as plot device
            } else if (device == 'ggplot2') {
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)
                plt <- ggplot(data = fig_df, aes_string(x='week', y=type)) + geom_line(aes(color=year)) +
                ggtitle(plotTitle) + labs(title = str_wrap(plotTitle, input$dimension[1]/15)) + geom_line(data = filter(fig_df, year == str_interp("${substring(Sys.time(),0,4)}")), size = 1.5,  aes(color=year))
                return(plt)

            # Condition for when the user uses plotly as plot device
            } else if (device == 'plotly') {
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)
                plt <- ggplotly(
                    ggplot(data=fig_df, aes_string(x='week', y=type)) + geom_line(aes(color=year)) +
                    ggtitle(plotTitle) + labs(title = str_wrap(plotTitle, input$dimension[1]/15)) + theme(plot.title = element_text(size=10)) + geom_line(data = filter(fig_df, year == str_interp("${substring(Sys.time(),0,4)}")), size = 1.5,  aes(color=year))
                )
                return(plt)
            
            # Condition in case of an unexpected error
            } else {
                return(text(x=0.5, y=0.5, col="black", cex=2, 'Unknown error'))
            }   
        }

        # Generate mortality df and plot
        gen_df_and_plot_mortality <- function(wk, yr, ccaas, age_groups, sexes, type, week_range_plot, yr_range_plot, device_plot) {
            mortPlotdf <- factors_df(
                wk=wk, 
                yr=yr, 
                ccaas=ccaas,
                age_groups=age_groups,
                sexes=sexes,
                type=type,
            )
            mortPlot <- plot_metric(
                df=mortPlotdf,
                week_range=week_range_plot,
                yr_range=yr_range_plot,
                type=type,
                device=device_plot
            )
            return(mortPlot)
        }

        # Generate life expectancy df and plot
        plot_lifeexp_or_lifetable <- function(wk, yr, ccaas, sexes, type, week_range_plot, yr_range_plot, device_plot) {
            # generate DF
            lifeExpDF <- LT(
                wk=wk,
                yr=yr,
                ccaas=ccaas,
                sexes=sexes
            )
            # only taking life exp at birth
            lifeExpDF_AB <- lifeExpDF[lifeExpDF$age == 'Y_LT5',]

            # life expectancy plot
            if (type == 'plot') {
                lifeExpPlot <- plot_metric(
                    df=data.frame(week=lifeExpDF$week, year=lifeExpDF$year, le=lifeExpDF$ex),
                    week_range=week_range_plot,
                    yr_range=yr_range_plot,
                    type=type,
                    device=device_plot
                )
                return(lifeExpPlot)

            # life table create and filter
            } else {
                return(lifeExpDF)
            }
        }

        # DYNAMIC UI CONTROLS
        # MORTALITY TAB
        # Select total or selectize CCAA
        output$selectCCAAMortalityUIOutput <- renderUI({
            if (input$selectCCAAMortalityTotal == 'select') {
                selectizeInput("selectCCAAMortality",
                  label = h5(strong("Select CCAAs")),
                  choices = c("",CCAA),
                  selected = NULL,
                  options = list(maxItems = length(CCAA))
                )
            }
        })

        # Select total or selectize Age Groups
        output$selectAgeGroupsMortalityUIOutput <- renderUI({
            if (input$selectAgeGroupsMortalityTotal == 'select') {
                selectizeInput("selectAgeMortality",
                  label = h5(strong("Select Age group(s)")),
                  choices = c("",AGE_GROUPS),
                  selected = NULL,
                  options = list(maxItems = length(AGE_GROUPS))
                )
            }
        })

        # plotly output
        # rendering the plotly UI to pass on the height from the session object
        output$plotlyUIGenMortality <- renderUI ({
            plotly::plotlyOutput(outputId = "mortalityPlotly",
                            # match width for a square plot
                            height = session$clientData$output_mortalityPlotly_width)
        })

        # LIFE EXPECTANCY TAB
        # Select total or selectize CCAA
        output$selectCCAALifeExpUIOutput <- renderUI({
            if (input$selectCCAALifeExpTotal == 'select') {
                selectizeInput("selectCCAALifeExp",
                  label = h5(strong("Select CCAAs")),
                  choices = c("",CCAA),
                  selected = NULL,
                  options = list(maxItems = length(CCAA))
                )
            }
        })

        # Select total or select Age Groups
        output$selectAgeGroupsLifeExpUIOutput <- renderUI({
            if (input$selectAgeGroupsLifeExpTotal == 'select') {
                selectInput("selectAgeLifeExp",
                  label = h5(strong("Select Age group(s)")),
                  choices = c("",AGE_GROUPS),
                  selected = NULL
                )
            }
        })

        # week slider for life table
        output$weekSliderSelectorLifeExpUIOutput <- renderUI({
            # life expectancy plot
            if (input$showLifeExpPlotOrLifeTable == 'plot') {
                sliderInput("weekSliderSelectorLifeExp",
                  label = h5(strong("Select week range to plot")),
                  min = 1,
                  max = 52,
                  value = c(1,52),
                  step = 1
                )
            # life table
            } else if (input$showLifeExpPlotOrLifeTable == 'life_table') {
                sliderInput("weekSliderSelectorLifeTable",
                  label = h5(strong("Select week to compute")),
                  min = 1,
                  max = 52,
                  value = 1,
                  step = 1
                )
            }
        })

        # year slider for life table
        output$yearSliderSelectorLifeExpUIOutput <- renderUI({
            # life expectancy plot
            if (input$showLifeExpPlotOrLifeTable == 'plot') {
                sliderInput("yearSliderSelectorLifeExp",
                  label = h5(strong("Select year range to plot")),
                  min = min(YEAR),
                  max = max(YEAR),
                  value = c(2015, max(YEAR)),
                  step = 1
                )
            # life table
            } else if (input$showLifeExpPlotOrLifeTable == 'life_table') {
                sliderInput("yearSliderSelectorLifeTable",
                  label = h5(strong("Select year to compute")),
                  min = min(YEAR),
                  max = max(YEAR),
                  value = 2021,
                  step = 1
                )
            }
        })

        # plotly output
        # rendering the plotly UI to pass on the height from the session object
        output$plotlyUIGenLifeExp <- renderUI ({
            plotly::plotlyOutput(outputId = "lifeExpPlotly",
                            # match width for a square plot
                            height = session$clientData$output_lifeExpPlotly_width)
        })

        # UPDATE DATABASE TAB
        # Text output for 
        # log output from command in update database
        output$lastUpdatedLog <- renderText({
            suppressWarnings(updateDBLogsLast())
            
        })
        # DEATH DB
        # Text output for
        # Indicator of provisional data
        output$provisionalDataIndicator <- renderText({
            suppressWarnings(updateEurostatLogsEarliestProvisional())
        })
        # Text output for
        # log output from last eurostat update script
        output$lastEurostatWeek <- renderText({
            suppressWarnings(updateEurostatLogsLast())
        })
        # Text output for
        # last repo week available, eurostat data (deaths)
        output$lastEurostatWeekRepo <- renderText({
            curr_year <- as.numeric(format(Sys.time(),'%Y'))
            last_avail_year <- max(death$year)
            last_avail_week <- max(death %>% dplyr::filter(year == curr_year) %>% dplyr::select(week))
            str_interp('Last date available from the repository: ${last_avail_year}, week: ${last_avail_week}')
        })
        # DB ID for eurostat Death DB
        output$eurostatDBID <- renderText({
            EurostatDBID
        })
        # POP DB
        # Text output for
        # log output from last INE update script
        output$lastINEWeek <- renderText({
            suppressWarnings(updateINELogsLast())
        })
        # DB ID for INE population DB
        output$INEDBID <- renderText({
            INEDBID
        })
        

        # DB TABLE TAB
        # Select total or selectize CCAA
        output$selectCCAADBTableUIOutput <- renderUI({
            if (input$selectCCAADBTableTotal == 'select') {
                selectizeInput("selectCCAADBTable",
                  label = h5(strong("Select CCAAs")),
                  choices = c("",CCAA),
                  selected = NULL,
                  options = list(maxItems = length(CCAA))
                )
            }
        })
        # Select total or selectize Age Groups
        output$selectAgeGroupsDBTableUIOutput <- renderUI({
            if (input$selectAgeGroupsDBTableTotal == 'select') {
                selectizeInput("selectAgeDBTable",
                  label = h5(strong("Select Age group(s)")),
                  choices = c("",AGE_GROUPS),
                  selected = NULL,
                  options = list(maxItems = length(AGE_GROUPS))
                )
            }
        })

        # MAPS TAB
        # Dynamic age group control, for all age groups, or selected
        output$selectAgeGroupsMapsUIOutput <- renderUI({
            if (input$selectAgeGroupsMapsTotal == 'select') {
                selectizeInput("selectAgeMaps",
                  label = h5(strong("Select Age group(s)")),
                  choices = c("",AGE_GROUPS),
                  selected = NULL,
                  options = list(maxItems = length(AGE_GROUPS))
                )
            }
        })
        # Map data table output
        output$mapDataOutput <- renderTable({
            genChloroplethTable()
        }, digits=10)
        # map output
        output$leafletMapOutput <- renderUI({
            leafletOutput("mapsPlot", height=input$dimension[2])
        })
        
        # PLOT OUTPUTS
        # Action button to generate mortality plots
        genMortPlot <- eventReactive(input$plotMortalityButton, {
            gen_df_and_plot_mortality(
                wk=WEEK, 
                yr=input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2], 
                ccaas=switch(input$selectCCAAMortalityTotal, 'all'=CCAA, 'select'=input$selectCCAAMortality),
                age_groups=switch(input$selectAgeGroupsMortalityTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMortality),
                sexes=input$selectSexesMortality,
                type=input$plotTypeMortality,
                week_range_plot=input$weekSliderSelectorMortality[1]:input$weekSliderSelectorMortality[2],
                yr_range_plot=input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2],
                device_plot=input$usePlotlyOrGgplotMortality
            )
        })

        # Mortality ratio plots
        observeEvent(input$usePlotlyOrGgplotMortality, {
            if (input$usePlotlyOrGgplotMortality == 'ggplot2') {
                shinyjs::hide('mortalityPlotly')
                shinyjs::show('mortalityPlot')
                output$mortalityPlot <- renderPlot(
                                            {genMortPlot()},
                                            # match width for a square plot
                                            height = function () {session$clientData$output_mortalityPlot_width}
                                        )
            } else if (input$usePlotlyOrGgplotMortality == 'plotly') {
                shinyjs::hide('mortalityPlot')
                shinyjs::show('mortalityPlotly')
                output$mortalityPlotly <- renderPlotly(
                                            {genMortPlot()},
                                        )
            }
        })

        # Action button to generate life expectancy plots or life table
        genLifeExpOutputs <- eventReactive(input$plotLifeExpButton, {
            weeks <- switch(input$showLifeExpPlotOrLifeTable, 'plot'=input$weekSliderSelectorLifeExp[1]:input$weekSliderSelectorLifeExp[2], 'life_table'=input$weekSliderSelectorLifeTable)
            years <- switch(input$showLifeExpPlotOrLifeTable, 'plot'=input$yearSliderSelectorLifeExp[1]:input$yearSliderSelectorLifeExp[2], 'life_table'=input$yearSliderSelectorLifeTable)
            plot_lifeexp_or_lifetable(
                wk=weeks, 
                yr=years, 
                ccaas=switch(input$selectCCAALifeExpTotal, 'all'=CCAA, 'select'=input$selectCCAALifeExp),
                # age_groups=switch(input$selectAgeGroupsLifeExpTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeLifeExp),
                sexes=input$selectSexesLifeExp,
                type=input$plotTypeLifeExp,
                week_range_plot=weeks,
                yr_range_plot=years,
                device_plot=input$usePlotlyOrGgplotLifeExp
            )
        })

        # life expectancy plots
        observeEvent(input$showLifeExpPlotOrLifeTable, {
            if (input$showLifeExpPlotOrLifeTable == 'plot') {
                if (input$usePlotlyOrGgplotLifeExp == 'ggplot2') {
                shinyjs::hide('lifeExpPlotly')
                shinyjs::hide('lifeTableTblOutput')
                shinyjs::show('lifeExpPlot')
                output$lifeExpPlot <- renderPlot(
                                            {genLifeExpOutputs()},
                                            # match width for a square plot
                                            height = function () {session$clientData$output_lifeExpPlot_width}
                                        )
                } else if (input$usePlotlyOrGgplotLifeExp == 'plotly') {
                    shinyjs::hide('lifeTableTblOutput')
                    shinyjs::hide('lifeExpPlot')
                    shinyjs::show('lifeExpPlotly')
                    output$lifeExpPlotly <- renderPlotly(
                                                {genLifeExpOutputs()},
                                            )
                }
            } else if (input$showLifeExpPlotOrLifeTable == 'life_table') {
                shinyjs::hide('lifeExpPlot')
                shinyjs::hide('lifeExpPlotly')
                shinyjs::show('lifeTableTblOutput')

            }
            
        })

        # Generate chloropleth map event
        genChloropleth <- eventReactive(input$plotMapsButton, {
            shinyjs::show('mapsPlot')
            shinyjs::show('mapDataOutput')
            shinyjs::show('mapDataLabels1')
            shinyjs::show('mapDataLabels2')
            df <- gen_map_data(
                wk=input$weekSliderSelectorMaps, 
                yr=input$yearSliderSelectorMaps, 
                age_groups=switch(input$selectAgeGroupsMapsTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMaps),
                sexes=input$selectSexesMaps,
                metric=input$plotMetricMaps
            )
            gen_chloropleth(
                dataset=df,
                metric=input$plotMetricMaps
            )
        })

        # Generate chloropleth map TABLE event
        genChloroplethTable <- eventReactive(input$plotMapsButton, {
            df <- gen_map_data(
                wk=input$weekSliderSelectorMaps, 
                yr=input$yearSliderSelectorMaps, 
                age_groups=switch(input$selectAgeGroupsMapsTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMaps),
                sexes=input$selectSexesMaps,
                metric=input$plotMetricMaps
            )@data
            metric <- df$metric
            df <- data.frame(CCAA=CCAA_SHORT[df$ccaa])
            df[,MORTALITY_PLOT_TYPE_R[input$plotMetricMaps]] <- metric
            df
        })

        # output for map
        output$mapsPlot <- renderLeaflet({genChloropleth()})
       
        # UPDATE DATABASE BUTTON
        observeEvent(input$updateDatabaseButton, {
            system('bash ./www/scripts/update_database_app.sh', wait=FALSE)
            systime <- Sys.time()
            updateActionButton(session=session, inputId='updateDatabaseButton', label="Update Database (Again)")
        })

        # log output from command in update database
        output$consoleLogsUpdateDatabase <- renderUI({
            HTML(updateDBLogs())
        })

        # DATABASE TABLE DOWNLOADER
        filtered_download_df <- reactive({filter_df_table(
                                            db=DBs[[input$selectDBTable]],
                                            wk=input$weekSliderSelectorDBTable[1]:input$weekSliderSelectorDBTable[2],
                                            yr=input$yearSliderSelectorDBTable[1]:input$yearSliderSelectorDBTable[2],
                                            ccaas=switch(input$selectCCAADBTableTotal, 'all'=CCAA, 'select'=input$selectCCAADBTable),
                                            age_groups=switch(input$selectAgeGroupsDBTableTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeDBTable),
                                            sexes=input$selectSexesDBTable
                                        )})
        output$downloadDBTable <- downloadHandler(
            filename = function() {
                str_interp('Filtered_data-${Sys.Date()}.csv')
            },
            content = function(file){
                write.csv(filtered_download_df(),file)
            }
        )
    } 
)

