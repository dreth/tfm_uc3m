# SERVER
shinyServer(
    function(input, output, session) {
        # REACTIVE VALUES
        updateDBLogs <- reactiveFileReader(intervalMillis=2000, session=session, filePath='../api/logs/update_database.log', readFunc=paste_readLines)
        updateDBLogsLast <- reactiveFileReader(intervalMillis=60000, session=session, filePath='../api/logs/update_history.log', readFunc=readLines)

        # PLOTTING FUNCTIONS
        # mortality plots
        plot_mortality <- function(df, week_range, yr_range, type='crmr', device='ggplot2') {
            # plot title construction
            selectedCCAAs <- switch(input$selectCCAAMortalityTotal, all='All', select=CCAA_SHORT[input$selectCCAAMortality])
            selectedAgeGroups <- switch(input$selectAgeGroupsMortalityTotal, all='All', select=AGE_GROUP_RANGES[input$selectAgeMortality])
            print(selectedCCAAs)
            plotTitle <- switch(type,
                                'em'='Excess Mortality',
                                'crmr'='Cumulative Relative Mortality Rate',
                                'cmr'='Cumulative Mortality Rate',
                                'bf'='Cumulative Improvement Factor',
                                'dc'='Death count'
                                )
            plotTitle <- str_interp('${plotTitle} for CCAA(s): ${paste(selectedCCAAs,collapse=", ")}, and Age Groups: ${paste(selectedAgeGroups,collapse=", ")}')

            # Condition in case of error
            if (suppressWarnings({df[1] == 'error'})) {
                return(text(x=0.5, y=0.5, col="black", cex=2, df[2]))

            # Condition for when user uses ggplot as plot device
            } else if (device == 'ggplot2') {
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)
                plt <- ggplot(data=fig_df, aes_string(x='week', y=type)) + geom_line(aes(colour=year)) +
                ggtitle(plotTitle) + labs(title = str_wrap(plotTitle, input$dimension[1]/15))
                return(plt)

            # Condition for when the user uses plotly as plot device
            } else if (device == 'plotly') {
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)
                plt <- ggplotly(
                    ggplot(data=fig_df, aes_string(x='week', y=type)) + geom_line(aes(colour=year)) +
                    ggtitle(plotTitle) + labs(title = str_wrap(plotTitle, input$dimension[1]/15)) + theme(plot.title = element_text(size=10))
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
            mortPlot <- plot_mortality(
                df=mortPlotdf,
                week_range=week_range_plot,
                yr_range=yr_range_plot,
                type=type,
                device=device_plot
            )
            return(mortPlot)
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

        # UI output for 
        # log output from command in update database
        # Mortality tab
        output$lastUpdatedLogMortality <- renderUI({
            HTML(updateDBLogsLast())
        })
        # Maps tab
        output$lastUpdatedLogMaps <- renderUI({
            HTML(updateDBLogsLast())
        })


        # UI output for
        # Indicator of provisional data
        # Mortality tab
        output$provisionalDataIndicatorMortality <- renderText({
            year <- as.numeric(format(Sys.time(),'%Y')) - 1
            str_interp("${year}-01-01")
        })
        # DB Tables tab
        output$provisionalDataIndicatorDBTables <- renderText({
            year <- as.numeric(format(Sys.time(),'%Y')) - 1
            str_interp("${year}-01-01")
        })
        # Maps tab
        output$provisionalDataIndicatorMaps <- renderText({
            year <- as.numeric(format(Sys.time(),'%Y')) - 1
            str_interp("${year}-01-01")
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
                shinyjs::show('mortalityPlotly')
                shinyjs::hide('mortalityPlot')
                output$mortalityPlotly <- renderPlotly(
                                            {genMortPlot()},
                                        )
            }
        })

        # Generate chloropleth map event
        genChloropleth <- eventReactive(input$plotMapsButton, {
            gen_chloropleth(
                wk=input$weekSliderSelectorMaps, 
                yr=input$yearSliderSelectorMaps, 
                age_groups=switch(input$selectAgeGroupsMapsTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMaps),
                sexes=input$selectSexesMaps,
                metric=input$plotMetricMaps
            )
        })

        # output for map
        output$mapsPlot <- renderLeaflet({genChloropleth()})
       
        # UPDATE DATABASE BUTTON
        observeEvent(input$updateDatabaseButton, {
            system('bash ./www/update_database_app.sh', wait=FALSE)
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

