# SERVER
shinyServer(
    function(input, output, session) {
# REACTIVE VALUES --------------------------------------------------------------------------
        # Reactive file readers for log files
        updateDBLogs <- reactiveFileReader(intervalMillis=2000, session=session, filePath='../data/logs/update_database.log', readFunc=paste_readLines)
        updateDBLogsLast <- reactiveFileReader(intervalMillis=4000, session=session, filePath='../data/logs/update_database.log', readFunc=readLines)
        updateEurostatLogsLast <- reactiveFileReader(intervalMillis=4000, session=session, filePath='../api/logs/last_eurostat_update.log', readFunc=readLines)
        updateEurostatLogsEarliestProvisional <- reactiveFileReader(intervalMillis=4000, session=session, filePath='../api/logs/earliest_eurostat_provisional.log', readFunc=readLines)
        updateINELogsLast <- reactiveFileReader(intervalMillis=4000, session=session, filePath='../api/logs/last_ine_update.log', readFunc=readLines)
        # reactive values
        mortalityRV <- reactiveValues(oldParams=c())
        mapsRV <- reactiveValues(oldParams=c())
        lifeExpRV <- reactiveValues(oldParams=c())

# PLOTTING/TABLE FUNCTIONS --------------------------------------------------------------------------
        # mortality plots
        plot_metric <- function(df, week_range, yr_range, type='crmr', device='ggplot2') {
            # plot title construction
            # plot name by metric
            plotTitle <- switch(type,
                                'em'='Excess Mortality',
                                'crmr'='Cumulative Relative Mortality Rate',
                                'cmr'='Cumulative Mortality Rate',
                                'mif'='Cumulative Improvement Factor',
                                'dc'='Death count',
                                'le'=ifelse(input$selectAgeGroupsLifeExpTotal=='at_birth', 'Life expectancy at birth', 'Life expectancy')
                                )

            # title elements conditions
            # Life expectancy
            if (type == 'le') {
                selectedCCAAs <- switch(input$selectCCAALifeExpTotal,'all'='All','select'=CCAA_SHORT[input$selectCCAALifeExp])
                selectedAgeGroups <- ifelse(input$selectAgeGroupsLifeExpTotal=='at_birth', '', AGE_GROUP_RANGES[input$selectAgeLifeExp])
                titleCCAA <- paste(selectedCCAAs,collapse=", ")
                titleAgeGroups <- ifelse(input$selectAgeGroupsLifeExpTotal=='at_birth','',str_interp(", and Age Group: ${selectedAgeGroups}"))
            # Mortality metrics
            } else {
                selectedCCAAs <- switch(input$selectCCAAMortalityTotal, 'all'='All', 'select'=CCAA_SHORT[input$selectCCAAMortality])
                selectedAgeGroups <- switch(input$selectAgeGroupsMortalityTotal, 'all'='All', 'select'=AGE_GROUP_RANGES[input$selectAgeMortality])
                titleCCAA <- paste(selectedCCAAs,collapse=", ")
                titleAgeGroups <- str_interp(", and Age Groups: ${paste(selectedAgeGroups,collapse=', ')}")
            }   

            # final plot title construction
            plotTitle <- str_interp('${plotTitle} for CCAA(s): ${titleCCAA}${titleAgeGroups}')

            # Condition in case of error
            if (suppressWarnings({df[1] == 'error'})) {
                return(text(x=0.5, y=0.5, col="black", cex=2, df[2]))

            # Condition for when user uses ggplot as plot device
            } else if (device == 'ggplot2') {

                # filtering df
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)
                

                # if selection includes current year
                if (as.numeric(substring(Sys.time(),0,4)) %in% fig_df$year) {
                    plt <- ggplot(data = fig_df, aes_string(x='week', y=type)) + 
                           geom_line(aes(color=year)) +
                           ggtitle(plotTitle) + 
                           labs(title = str_wrap(plotTitle, input$dimension[1]/15)) + 
                           geom_line(data = filter(fig_df, year == str_interp("${substring(Sys.time(),0,4)}")), size = 1.5,  aes(color=year))

                # if selection does not include current year
                } else {
                    plt <- ggplot(data = fig_df, aes_string(x='week', y=type)) + geom_line(aes(color=year)) +
                           ggtitle(plotTitle) + 
                           labs(title = str_wrap(plotTitle, input$dimension[1]/15))
                }
                
                # returning the plot object
                return(plt)

            # Condition for when the user uses plotly as plot device
            } else if (device == 'plotly') {

                # filtering df
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)

                # if selection includes current year
                if (as.numeric(substring(Sys.time(),0,4)) %in% fig_df$year) {
                    plt <- ggplotly(
                        ggplot(data = fig_df, aes_string(x='week', y=type)) + 
                        geom_line(aes(color=year)) +
                        ggtitle(plotTitle) + 
                        labs(title = str_wrap(plotTitle, input$dimension[1]/15)) + 
                        theme(plot.title = element_text(size=10)) + 
                        geom_line(data = filter(fig_df, year == str_interp("${substring(Sys.time(),0,4)}")), size = 1.5,  aes(color=year))
                    )

                # if selection does not include current year
                } else {
                    plt <- ggplotly(
                        ggplot(data = fig_df, aes_string(x='week', y=type)) + 
                        geom_line(aes(color=year)) +
                        ggtitle(plotTitle) + 
                        labs(title = str_wrap(plotTitle, input$dimension[1]/15)) + theme(plot.title = element_text(size=10))
                    )
                }

                # returning the plot object
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
        plot_lifeexp_or_lifetable <- function(wk, yr, ccaas, age_groups, sexes, type,week_range_plot, yr_range_plot, device_plot) {
            # generate DF
            lifeExpDF <- LT(
                wk=wk,
                yr=yr,
                ccaas=ccaas,
                sexes=sexes
            )
            # only taking life exp at birth
            lifeExpDF_AB <- lifeExpDF[lifeExpDF$age == age_groups,]
            
            # life expectancy plot
            if (type == 'le') {
                lePlot <- plot_metric(
                    df=data.frame(week=lifeExpDF_AB$week, year=lifeExpDF_AB$year, le=lifeExpDF_AB$ex),
                    week_range=week_range_plot,
                    yr_range=yr_range_plot,
                    type=type,
                    device=device_plot
                )
                return(lePlot)

            # life table create and filter
            } else {
                tableDF <- lifeExpDF[lifeExpDF$week == wk & lifeExpDF$year == yr,]
                return(tableDF)
            }
        }

        # function to plot life table/plot for download handler, avoids repetition
        LELT_download <- function() {
            weeks=switch(input$showLifeExpPlotOrLifeTable, 'plot'=input$weekSliderSelectorLifeExp[1]:input$weekSliderSelectorLifeExp[2], 'life_table'=input$weekSliderSelectorLifeTable)
            years=switch(input$showLifeExpPlotOrLifeTable, 'plot'=input$yearSliderSelectorLifeExp[1]:input$yearSliderSelectorLifeExp[2], 'life_table'=input$yearSliderSelectorLifeTable)
            plot_lifeexp_or_lifetable(
                wk=weeks, 
                yr=years, 
                ccaas=switch(input$selectCCAALifeExpTotal, 'all'=CCAA, 'select'=input$selectCCAALifeExp),
                age_groups=switch(input$selectAgeGroupsLifeExpTotal, 'at_birth'='Y_LT5', 'select'=input$selectAgeLifeExp),
                sexes=input$selectSexesLifeExp,
                type=switch(input$showLifeExpPlotOrLifeTable,'plot'='le','life_table'='life_table'),
                week_range_plot=weeks,
                yr_range_plot=years,
                device_plot='ggplot2'
            )
        }

# DYNAMIC UI CONTROLS
# MORTALITY TAB -------------------------------------------------------------------------- 
        # UI OUTPUTS
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

        # Selector for year, choices depend on what metric is selected
        output$yearSelectorUIOutputMortality <- renderUI({
            if (input$plotTypeMortality == 'em') {
                sliderInput('yearSliderSelectorMortality',
                    label = h5(strong('Select year range to plot')),
                    min = min(YEAR)+5,
                    max = max(YEAR),
                    value = c(2015, max(YEAR)),
                    step = 1
                )
            } else if (input$plotTypeMortality == 'mif') {
                sliderInput('yearSliderSelectorMortality',
                    label = h5(strong('Select year range to plot')),
                    min = min(YEAR)+1,
                    max = max(YEAR),
                    value = c(2015, max(YEAR)),
                    step = 1
                )
            } else {
                sliderInput('yearSliderSelectorMortality',
                    label = h5(strong('Select year range to plot')),
                    min = min(YEAR),
                    max = max(YEAR),
                    value = c(2015, max(YEAR)),
                    step = 1
                )
            }
        })

        # text output for when parameters have been changed
        output$mortalityTextUIOutput <- renderUI({
            # currently selected params
            currParams <- tryCatch(c(input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2], switch(input$selectCCAAMortalityTotal, 'all'=CCAA, 'select'=input$selectCCAAMortality), switch(input$selectAgeGroupsMortalityTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMortality), input$selectSexesMortality, input$plotTypeMortality, input$weekSliderSelectorMortality[1]:input$weekSliderSelectorMortality[2], input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2]), error=function(e) {0})
            # comparing old and currently selected params
            comparator <- mortalityRV$oldParams == currParams
            # outputting message or empty string depending on diff
            if (FALSE %in% comparator) {
                div(id='mortalityParamsChangedH5',h5(strong('Params changed - Click to regenerate plot')))
            } else {
                span('')
            }
        })

        # plotly output
        # rendering the plotly UI to pass on the height from the session object
        output$plotlyUIGenMortality <- renderUI({
            plotly::plotlyOutput(outputId = "mortalityPlotly",
                            # match width for a square plot
                            height = session$clientData$output_mortalityPlotly_width)
        })

        # output for image download dimension (image)
        # manual  or custom
        observeEvent(input$plotDownloadSizeSelectorMortality, {
            if (input$plotDownloadSizeSelectorMortality == 'predefined') {
                output$plotDownloadSizeControlsMortalityUIOutput <- renderUI({
                    selectInput("selectDimensionsMortalityDownload",
                        label = h5(strong("Select dimension for download")),
                        choices = DOWNLOAD_SIZE_PREDEF,
                        selected = 800
                    )
                })
                shinyjs::hide('heightMortalityDownload')
            } else if (input$plotDownloadSizeSelectorMortality == 'custom') {
                output$plotDownloadSizeControlsMortalityUIOutput <- renderUI({
                    numericInput("widthMortalityDownload",
                        label=h5(strong("Width of the resulting image")),
                        value=500,
                        min=1,
                        max=10000,
                        step=1
                    )
                })
                output$plotDownloadSizeControlsMortalityUIOutputNS2 <- renderUI({
                    numericInput("heightMortalityDownload",
                        label=h5(strong("Height of the resulting image")),
                        value=500,
                        min=1,
                        max=10000,
                        step=1
                    )
                })
                shinyjs::show('heightMortalityDownload')
            }
        })

        # PLOT OUTPUTS
        # Action button to generate mortality plots
        genMortPlot <- eventReactive(input$plotMortalityButton, {
            # saving parameters at the time of the plot
            mortalityRV$oldParams <- c(input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2], switch(input$selectCCAAMortalityTotal, 'all'=CCAA, 'select'=input$selectCCAAMortality), switch(input$selectAgeGroupsMortalityTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMortality), input$selectSexesMortality, input$plotTypeMortality, input$weekSliderSelectorMortality[1]:input$weekSliderSelectorMortality[2], input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2])
            # generate df and plot
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

        # PLOT DOWNLOAD BUTTON
        output$downloadPlotMortality <- downloadHandler(
            filename = input$plotTypeMortality,
            content = function(file) {
                ggsave(
                    file,
                    width=switch(input$plotDownloadSizeSelectorMortality, 'predefined'=as.numeric(input$selectDimensionsMortalityDownload)*0.01333333, 'custom'=input$widthMortalityDownload*0.01333333),
                    height=switch(input$plotDownloadSizeSelectorMortality, 'predefined'=as.numeric(input$selectDimensionsMortalityDownload)*0.01333333, 'custom'=input$heightMortalityDownload*0.01333333),
                    plot=gen_df_and_plot_mortality(
                            wk=WEEK, 
                            yr=input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2], 
                            ccaas=switch(input$selectCCAAMortalityTotal, 'all'=CCAA, 'select'=input$selectCCAAMortality),
                            age_groups=switch(input$selectAgeGroupsMortalityTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMortality),
                            sexes=input$selectSexesMortality,
                            type=input$plotTypeMortality,
                            week_range_plot=input$weekSliderSelectorMortality[1]:input$weekSliderSelectorMortality[2],
                            yr_range_plot=input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2],
                            device_plot='ggplot2'
                        ),
                    device=input$plotDownloadFormatMortality
                )
            }
        )

#  LIFE EXPECTANCY TAB ----------------------------------------------------------------------------------
        # UI OUTPUTS
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
            # load life exp plot after rendering everything
            delay(1000, click('plotLifeExpButton'))
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
                  min = min(YEAR)+1,
                  max = max(YEAR),
                  value = c(2015, max(YEAR)),
                  step = 1
                )
            # life table
            } else if (input$showLifeExpPlotOrLifeTable == 'life_table') {
                sliderInput("yearSliderSelectorLifeTable",
                  label = h5(strong("Select year to compute")),
                  min = min(YEAR)+1,
                  max = max(YEAR),
                  value = 2021,
                  step = 1
                )
            }
        })

        # plotly output
        # rendering the plotly UI to pass on the height from the session object
        output$plotlyUIGenLifeExp <- renderUI({
            plotly::plotlyOutput(outputId = "lifeExpPlotly",
                            # match width for a square plot
                            height = session$clientData$output_lifeExpPlotly_width)
        })

        # text output for when parameters have been changed
        output$lifeExpTextUIOutput <- renderUI({
            # weeks
            weeks <- switch(input$showLifeExpPlotOrLifeTable, 'plot'=input$weekSliderSelectorLifeExp[1]:input$weekSliderSelectorLifeExp[2], 'life_table'=input$weekSliderSelectorLifeTable)
            # years
            years <- switch(input$showLifeExpPlotOrLifeTable, 'plot'=input$yearSliderSelectorLifeExp[1]:input$yearSliderSelectorLifeExp[2], 'life_table'=input$yearSliderSelectorLifeTable)
            # currently selected params
            currParams <- tryCatch(c(weeks, years, switch(input$selectCCAALifeExpTotal, 'all'=CCAA, 'select'=input$selectCCAALifeExp), switch(input$selectAgeGroupsLifeExpTotal, 'at_birth'='Y_LT5', 'select'=input$selectAgeLifeExp), input$selectSexesLifeExp, switch(input$showLifeExpPlotOrLifeTable,'plot'='le','life_table'='life_table')), error=function(e) {0})
            # comparing entries
            comparator <- lifeExpRV$oldParams == currParams
            # outputting the changed params message or empty span
            if (FALSE %in% comparator) {
                div(id='lifeExpParamsChangedH5',h5(strong(switch(input$showLifeExpPlotOrLifeTable,'plot'='Params changed - Click to regenerate plot', 'life_table'='Params changed - Click to regenerate table'))))
            } else {
                span('')
            }
        })

        # PLOT/TABLE OUTPUTS
        # Action button to generate life expectancy plots or life table
        genLifeExpOutputs <- eventReactive(input$plotLifeExpButton, {
            # weeks
            weeks <- switch(input$showLifeExpPlotOrLifeTable, 'plot'=input$weekSliderSelectorLifeExp[1]:input$weekSliderSelectorLifeExp[2], 'life_table'=input$weekSliderSelectorLifeTable)
            # years
            years <- switch(input$showLifeExpPlotOrLifeTable, 'plot'=input$yearSliderSelectorLifeExp[1]:input$yearSliderSelectorLifeExp[2], 'life_table'=input$yearSliderSelectorLifeTable)
            # reactive value to save old params
            lifeExpRV$oldParams <- c(weeks, years, switch(input$selectCCAALifeExpTotal, 'all'=CCAA, 'select'=input$selectCCAALifeExp), switch(input$selectAgeGroupsLifeExpTotal, 'at_birth'='Y_LT5', 'select'=input$selectAgeLifeExp), input$selectSexesLifeExp, switch(input$showLifeExpPlotOrLifeTable,'plot'='le','life_table'='life_table'))
            # running the function
            plot_lifeexp_or_lifetable(
                wk=weeks, 
                yr=years, 
                ccaas=switch(input$selectCCAALifeExpTotal, 'all'=CCAA, 'select'=input$selectCCAALifeExp),
                age_groups=switch(input$selectAgeGroupsLifeExpTotal, 'at_birth'='Y_LT5', 'select'=input$selectAgeLifeExp),
                sexes=input$selectSexesLifeExp,
                type=switch(input$showLifeExpPlotOrLifeTable,'plot'='le','life_table'='life_table'),
                week_range_plot=weeks,
                yr_range_plot=years,
                device_plot=input$usePlotlyOrGgplotLifeExp
            )
        })

        # life expectancy plots
        observeEvent(input$usePlotlyOrGgplotLifeExp, {
            if (input$usePlotlyOrGgplotLifeExp == 'ggplot2') {
            shinyjs::hide('lifeExpPlotly')
            shinyjs::hide('lifeTableOutput')
            shinyjs::show('lifeExpPlot')
            output$lifeExpPlot <- renderPlot(
                                        {genLifeExpOutputs()},
                                        # match width for a square plot
                                        height = function () {session$clientData$output_lifeExpPlot_width}
                                    )
            } else {
                shinyjs::hide('lifeTableOutput')
                shinyjs::hide('lifeExpPlot')
                shinyjs::show('lifeExpPlotly')
                output$lifeExpPlotly <- renderPlotly(
                                            {genLifeExpOutputs()},
                                        )
            }
        })

        # life exp plots or life table
        observeEvent(input$showLifeExpPlotOrLifeTable, {
            if (input$showLifeExpPlotOrLifeTable == 'plot') {
                # download button for plot
                output$downloadPlotOrTableUIOutput <- renderUI({
                    downloadButton("downloadPlotLifeExp",
                        label=h4(strong("Download plot"))
                    )
                })

                # download format selector
                output$lifeExpPlotDownloadFormatUIOutput <- renderUI({
                    selectInput("plotDownloadFormatLifeExp",
                        label = h5(strong("Select image format")),
                        choices = DOWNLOAD_IMAGE_FORMAT,
                        selected = 'png'
                    )
                })

                # menu header, for plot
                output$lifeExpOrTableHeaderUIOutput <- renderUI({h5(strong('Plot parameters'))})
                output$lifeExpOrTableDownloadHeaderUIOutput <- renderUI({h4(strong('Image download options'))})

                # showing plot/table outputs
                shinyjs::show('usePlotlyOrGgplotLifeExp')
                shinyjs::show('selectAgeGroupsLifeExpTotal')
                shinyjs::hide('lifeTableOutput')

                # showing plot download controls
                shinyjs::show('lifeExpPlotDownloadFormatUIOutput')
                shinyjs::show('plotDownloadSizeSelectorLifeExp')
                shinyjs::show('plotDownloadSizeControlsLifeExpUIOutput')
                shinyjs::show('plotDownloadSizeControlsLifeExpUIOutputNS2')

                # showing or hiding plot types depending on selection
                if (input$usePlotlyOrGgplotLifeExp == 'ggplot2') {
                    shinyjs::show('lifeExpPlot')
                    shinyjs::hide('lifeExpPlotly')
                } else {
                    shinyjs::hide('lifeExpPlot')
                    shinyjs::show('lifeExpPlotly')
                }
            } else if (input$showLifeExpPlotOrLifeTable == 'life_table') {
                # download button for table
                output$downloadPlotOrTableUIOutput <- renderUI({
                    downloadButton("downloadTableLifeExp",
                        label=h4(strong("Download table"))
                    )
                })

                # table output for life table
                output$lifeTableOutput <- renderTable({
                    genLifeExpOutputs()
                })

                # menu header, for table 
                output$lifeExpOrTableHeaderUIOutput <- renderUI({h5(strong('Table parameters'))})
                output$lifeExpOrTableDownloadHeaderUIOutput <- renderUI({h4(strong('Table download options'))})

                # hiding plot settings/outputs and showing table output
                shinyjs::hide('lifeExpPlot')
                shinyjs::hide('lifeExpPlotly')
                shinyjs::show('lifeTableOutput')
                shinyjs::hide('usePlotlyOrGgplotLifeExp')
                shinyjs::hide('selectAgeGroupsLifeExpTotal')

                # hiding download controls for plot
                shinyjs::hide('lifeExpPlotDownloadFormatUIOutput')
                shinyjs::hide('plotDownloadSizeControlsLifeExpUIOutput')
                shinyjs::hide('plotDownloadSizeControlsLifeExpUIOutputNS2')
                shinyjs::hide('plotDownloadSizeSelectorLifeExp')
            }
        })

        # toggle between predefined and custom size
        observeEvent(input$plotDownloadSizeSelectorLifeExp, {
            if (input$plotDownloadSizeSelectorLifeExp == 'predefined') {
                output$plotDownloadSizeControlsLifeExpUIOutput <- renderUI({
                    selectInput("selectDimensionsLifeExpDownload",
                        label = h5(strong("Select dimension for download")),
                        choices = DOWNLOAD_SIZE_PREDEF,
                        selected = 800
                    )
                })
                shinyjs::hide('heightLifeExpDownload')
            } else if (input$plotDownloadSizeSelectorLifeExp == 'custom') {
                output$plotDownloadSizeControlsLifeExpUIOutput <- renderUI({
                    numericInput("widthLifeExpDownload",
                        label=h5(strong("Width of the resulting image")),
                        value=500,
                        min=1,
                        max=10000,
                        step=1
                    )
                })
                output$plotDownloadSizeControlsLifeExpUIOutputNS2 <- renderUI({
                    numericInput("heightLifeExpDownload",
                        label=h5(strong("Height of the resulting image")),
                        value=500,
                        min=1,
                        max=10000,
                        step=1
                    )
                })
                shinyjs::show('heightLifeExpDownload')
            }
        })

        # DOWNLOAD BUTTONS
        # download plot
        output$downloadPlotLifeExp <- downloadHandler(
            filename = str_interp("LifeExpectancy"),
            content = function(file) {
                ggsave(
                    file,
                    width=switch(input$plotDownloadSizeSelectorLifeExp, 'predefined'=as.numeric(input$selectDimensionsLifeExpDownload)*0.01333333, 'custom'=input$widthLifeExpDownload*0.01333333),
                    height=switch(input$plotDownloadSizeSelectorLifeExp, 'predefined'=as.numeric(input$selectDimensionsLifeExpDownload)*0.01333333, 'custom'=input$heightLifeExpDownload*0.01333333),
                    plot=LELT_download(),
                    device=input$plotDownloadFormatLifeExp
                )
            }
        )

        # download table
        output$downloadTableLifeExp <- downloadHandler(
            filename = str_interp("LifeTable-wk${input$weekSliderSelectorLifeTable}-${input$yearSliderSelectorLifeTable}.csv"),
            content = function(file) {
                 write.csv(LELT_download(),file)
            }
        )


# UPDATE DATABASE TAB -------------------------------------------------------------------------------------
        # UI OUTPUTS
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

        # UPDATE DATABASE BUTTON
        observeEvent(input$updateDatabaseButton, {
            system('bash ./www/scripts/update_database.sh', wait=FALSE)
            systime <- Sys.time()
            updateActionButton(session=session, inputId='updateDatabaseButton', label="Update Database (Again)")
        })

        # log output from command in update database
        output$consoleLogsUpdateDatabase <- renderUI({
            HTML(updateDBLogs())
        })
        

# DB TABLE TAB -------------------------------------------------------------------------------------
        # UI OUTPUTS
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

        # DB table download preview
        output$tableDownloadPreviewDBTable <- renderDataTable({
            filter_df_table(
                db=DBs[[input$selectDBTable]],
                wk=input$weekSliderSelectorDBTable[1]:input$weekSliderSelectorDBTable[2],
                yr=input$yearSliderSelectorDBTable[1]:input$yearSliderSelectorDBTable[2],
                ccaas=switch(input$selectCCAADBTableTotal, 'all'=CCAA, 'select'=input$selectCCAADBTable),
                age_groups=switch(input$selectAgeGroupsDBTableTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeDBTable),
                sexes=input$selectSexesDBTable
            )
        })

# MAPS TAB -------------------------------------------------------------------------------------
        # UI OUTPUTS
        # Dynamic age group control, for all age groups, or selected
        output$selectAgeGroupsMapsUIOutput <- renderUI({
            if (input$selectAgeGroupsMapsTotal == 'select') {
                selectizeInput("selectAgeMaps",
                  label = h5(strong("Select Age group(s)")),
                  choices = c("",AGE_GROUPS),
                  selected = NULL,
                  options = list(maxItems = length(AGE_GROUPS))
                )
            } else if (input$selectAgeGroupsLifeExpTotalMaps == 'select') {
                selectInput("selectAgeMaps",
                  label = h5(strong("Select Age group")),
                  choices = AGE_GROUPS,
                  selected = 'Y_LT5'
                )
            }
        })
        
        # map output
        output$leafletMapOutput <- renderUI({
            leafletOutput("leafletMapsPlot", height=input$dimension[2])
        })

        # Selector for year, choices depend on what metric is selected
        output$yearSelectorUIOutputMaps <- renderUI({
            if (input$plotMetricMaps == 'em') {
                sliderInput('yearSliderSelectorMaps',
                    label = h5(strong('Select year to plot')),
                    min = min(YEAR)+5,
                    max = max(YEAR),
                    value = max(YEAR),
                    step = 1
                )
            } else if (input$plotMetricMaps == 'mif' | input$plotMetricMaps == 'le') {
                sliderInput('yearSliderSelectorMaps',
                    label = h5(strong('Select year to plot')),
                    min = min(YEAR)+1,
                    max = max(YEAR),
                    value = max(YEAR),
                    step = 1
                )
            } else {
                sliderInput('yearSliderSelectorMaps',
                    label = h5(strong('Select year to plot')),
                    min = min(YEAR),
                    max = max(YEAR),
                    value = max(YEAR),
                    step = 1
                )
            }
        })

        # text output for when parameters have been changed
        output$mapsTextUIOutput <- renderUI({
            # currently selected params
            currParams <- tryCatch(c(input$weekSliderSelectorMaps, input$yearSliderSelectorMaps, ifelse(input$plotMetricMaps != 'le', switch(input$selectAgeGroupsMapsTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMaps), switch(input$selectAgeGroupsLifeExpTotalMaps, 'at_birth'='Y_LT5', 'select'=input$selectAgeMaps)), input$selectSexesMaps, input$plotMetricMaps, input$plotLibraryMaps), error=function(e) {0})
            # comparing entries
            comparator <- mapsRV$oldParams == currParams
            # outputting the changed params message or empty span
            if (FALSE %in% comparator) {
                div(id='mapsParamsChangedH5',h5(strong('Params changed - Click to regenerate plot')))
            } else {
                span('')
            }
        })

        # life expectancy at birth or select age group option
        observeEvent(input$plotMetricMaps, {
            if (input$plotMetricMaps != 'le') {
                shinyjs::show('selectAgeGroupsMapsTotal')
                shinyjs::hide('selectAgeGroupsLifeExpTotalMaps')
            } else {
                shinyjs::hide('selectAgeGroupsMapsTotal')
                shinyjs::show('selectAgeGroupsLifeExpTotalMaps')
            }
        })

        # showing or hiding life exp age group selection based on at birth or not
        observeEvent(input$selectAgeGroupsLifeExpTotalMaps, {
            if (input$selectAgeGroupsLifeExpTotalMaps == 'at_birth') {
                shinyjs::hide('selectAgeMaps')
            } else {
                shinyjs::show('selectAgeMaps')
            }
        })

        # PLOT/TABLE OUTPUTS
        # Map data table output
        output$mapDataOutput <- renderTable({
            genChoroplethTable()
        }, digits=10)

        # Generate choropleth map event
        genChoropleth <- eventReactive(input$plotMapsButton, {
            # showing outputs
            shinyjs::show('leafletMapsPlot')
            shinyjs::show('mapDataOutput')
            shinyjs::show('mapDataLabels1')
            shinyjs::show('mapDataLabels2')
            # saving old params
            mapsRV$oldParams <- c(input$weekSliderSelectorMaps, input$yearSliderSelectorMaps, ifelse(input$plotMetricMaps != 'le', switch(input$selectAgeGroupsMapsTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMaps), switch(input$selectAgeGroupsLifeExpTotalMaps, 'at_birth'='Y_LT5', 'select'=input$selectAgeMaps)), input$selectSexesMaps, input$plotMetricMaps, input$plotLibraryMaps)
            # generating map data
            df <- gen_map_data(
                wk=input$weekSliderSelectorMaps, 
                yr=input$yearSliderSelectorMaps, 
                age_groups=ifelse(input$plotMetricMaps != 'le', switch(input$selectAgeGroupsMapsTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMaps), switch(input$selectAgeGroupsLifeExpTotalMaps, 'at_birth'='Y_LT5', 'select'=input$selectAgeMaps)),
                sexes=input$selectSexesMaps,
                metric=input$plotMetricMaps,
                shape_data=switch(input$plotLibraryMaps, 'leaflet'=esp_leaflet, 'ggplot2'=esp_ggplot)
            )
            # generating the map
            gen_choropleth(
                dataset=df,
                library=input$plotLibraryMaps,
                metric=input$plotMetricMaps,
                wk=input$weekSliderSelectorMaps, 
                yr=input$yearSliderSelectorMaps
            )
        })

        # Generate choropleth map TABLE event
        genChoroplethTable <- eventReactive(input$plotMapsButton, {
            df <- gen_map_data(
                wk=input$weekSliderSelectorMaps, 
                yr=input$yearSliderSelectorMaps, 
                age_groups=ifelse(input$plotMetricMaps != 'le', switch(input$selectAgeGroupsMapsTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMaps), switch(input$selectAgeGroupsLifeExpTotalMaps, 'at_birth'='Y_LT5', 'select'=input$selectAgeMaps)),
                sexes=input$selectSexesMaps,
                metric=input$plotMetricMaps,
                shape_data=esp_leaflet
            )@data
            metric <- df$metric
            df <- data.frame(CCAA=CCAA_SHORT[df$ccaa], metric=metric)
            names(df) <- c("CCAA", MORTALITY_PLOT_TYPE_R[input$plotMetricMaps])
            df
        })

        # outputting the map upon switching the plotting library
        observeEvent(input$plotLibraryMaps, {
            if (input$plotLibraryMaps == 'leaflet') {
                output$leafletMapsPlot <- renderLeaflet({genChoropleth()})
                shinyjs::show('leafletMapsPlot')
                shinyjs::show('leafletMapOutput')
                shinyjs::hide('ggplo2MapPlot')
            } else if (input$plotLibraryMaps == 'ggplot2') {
                output$ggplot2MapPlot <- renderPlot({genChoropleth()}, 
                                                    height = function () {session$clientData$output_ggplot2MapPlot_width})
                shinyjs::show('ggplot2MapPlot')
                shinyjs::hide('leafletMapsPlot')
                shinyjs::hide('leafletMapOutput')
            }
        })

# DOCS TAB -------------------------------------------------------------------------- 
        observeEvent(input$docsSectionSelect, {
            section <- input$docsSectionSelect
            output$docsSectionUIOutput <- renderUI({
                includeMarkdown(str_interp('../docs/sections/${section}.md'))
            })
        })
# INITIALIZE PLOTS -------------------------------------------------------------------------- 
        # Timer to initialize all plots after app is loaded
        delay(1500, click('plotMortalityButton'))
        delay(1000, click('plotMapsButton'))
    }
)

