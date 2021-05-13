# SERVER
shinyServer(
    function(input, output, session) {
        # REACTIVE VALUES
        updateDBLogs <- reactiveFileReader(intervalMillis=2000, session=session, filePath='../api/logs/update_database.log', readFunc=paste_readLines)
        updateDBLogsLast <- reactiveFileReader(intervalMillis=2000, session=session, filePath='../api/logs/update_history.log', readFunc=readLines)

        
        # PLOTTING FUNCTIONS
        # mortality plots
        plot_mortality <- function(df, week_range, yr_range, type='crmr', device='ggplot2') {
            if (suppressWarnings({df[1] == 'error'})) {
                return(text(x=0.5, y=0.5, col="black", cex=2, df[2]))
            # Condition for when user uses ggplot as plot device
            } else if (device == 'ggplot2') {
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)
                plt <- ggplot(data=fig_df, aes_string(x='week', y=type)) + geom_line(aes(colour=year)) +
                ggtitle(
                    switch(type,
                        'em'='Excess Mortality',
                        'crmr'='Cumulative Relative Mortality Rate',
                        'cmr'='Cumulative Mortality Rate',
                        'bf'='Cumulative Improvement Factor'
                    ))
                return(plt)
            # Condition for when the user uses plotly as plot device
            } else if (device == 'plotly') {
                plotTitle <- switch(type,
                                'em'='Excess Mortality',
                                'crmr'='Cumulative Relative Mortality Rate',
                                'cmr'='Cumulative Mortality Rate',
                                'bf'='Cumulative Improvement Factor'
                            )
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)
                fig <- plot_ly(fig_df, x =~week, y = ~fig_df[[type]], color=~year, group=~year, type = 'scatter', mode='lines')
                fug <- fig %>% layout(title = plotTitle)
                return(fig)
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

        # UI output for 
        # log output from command in update database
        output$lastUpdatedLogMortality <- renderUI({
            HTML(updateDBLogsLast())
        })

        # plotly output
        # rendering the plotly UI to pass on the height from the session object
        output$plotlyUIGenMortality <- renderUI ({
            plotly::plotlyOutput(outputId = "mortalityPlotly",
                            # match width for a square plot
                            height = session$clientData$output_mortalityPlotly_width)
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

