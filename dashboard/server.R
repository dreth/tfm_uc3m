# IMPORTING LIBRARIES
require(shiny)
require(shinydashboard)

# SERVER
shinyServer(
    function(input, output, session) {
        # REACTIVE VALUES
        # rv_stream <- reactiveValues()
        updateDBLogs <- reactiveFileReader(intervalMillis=2000, session=session, filePath='../api/logs/update_database.log', readFunc=paste_readLines)
        
        # PLOTTING FUNCTIONS
        # mortality plots
        plot_mortality <- function(df, week_range, yr_range, type='crmr') {
            if (suppressWarnings({df[1] == 'error'})) {
                return(text(x=0.5, y=0.5, col="black", cex=2, df[2]))
            } else if (reactive(input$usePlotlyOrGgplotMortality) == 'ggplot2') {
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
            } else if (reactive(input$usePlotlyOrGgplotMortality) == 'plotly') {
                plotTitle <- switch(type,
                                'em'='Excess Mortality',
                                'crmr'='Cumulative Relative Mortality Rate',
                                'cmr'='Cumulative Mortality Rate',
                                'bf'='Cumulative Improvement Factor'
                            )
                fig_df <- df %>% dplyr::filter(year %in% yr_range & week %in% week_range)
                fig <- plot_ly(df, x = 'week', y = type, color='year', title=plotTitle) 
                fug <- fig %>% add_lines()
                return(fig)
            } else {
                return(text(x=0.5, y=0.5, col="black", cex=2, 'Unknown error'))
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

        # Output plotly or ggplot2 plotoutput depending on the
        # selected plotting library/device
        output$ggplotOrPlotlyMortalityUIOutput <- renderUI({
            if (input$usePlotlyOrGgplotMortality == 'ggplot2') {
                plotOutput(outputId = "mortalityPlot")
            } else {
                plotly::plotlyOutput(outputId = "mortalityPlot")
            }
        })

        # PLOT OUTPUTS
        # Action button to generate mortality plots
        genMortPlot <- eventReactive(input$plotMortalityButton, {
            mortPlotdf <- factors_df(
                wk=WEEK, 
                yr=input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2], 
                ccaas=switch(input$selectCCAAMortalityTotal, 'all'=CCAA, 'select'=input$selectCCAAMortality),
                age_groups=switch(input$selectAgeGroupsMortalityTotal, 'all'=AGE_GROUPS, 'select'=input$selectAgeMortality),
                sexes=input$selectSexesMortality,
                type=input$plotTypeMortality
            )
            mortPlot <- plot_mortality(
                df=mortPlotdf,
                week_range=input$weekSliderSelectorMortality[1]:input$weekSliderSelectorMortality[2],
                yr_range=input$yearSliderSelectorMortality[1]:input$yearSliderSelectorMortality[2],
                type=input$plotTypeMortality
            )
            return(mortPlot)
        })

        # Mortality ratio plots
        output$mortalityPlot <- renderPlot({
            genMortPlot()
        },
            # match width for a square plot
            height = function () {
                session$clientData$output_mortalityPlot_width
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
    } 
)

