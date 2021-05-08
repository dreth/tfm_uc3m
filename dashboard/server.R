# IMPORTING LIBRARIES
require(shiny)
require(shinydashboard)

# SERVER
shinyServer(
    function(input, output, session) {
        # REACTIVE VALUES
        # rv_stream <- reactiveValues()
        updateDBLogs <- reactiveFileReader(intervalMillis=1000, session=session, filePath='./logs/update_database_log.txt', readFunc=paste_readLines)

        # DYNAMIC UI CONTROLS
        # Select total or selectize CCAA - Mortality
        output$selectCCAAMortalityUIOutput <- renderUI({
            if (input$selectCCAAMortalityTotal == 'select') {
                selectizeInput("selectCCAAMortality",
                  label = h5(strong("Select CCAAs")),
                  choices = CCAA,
                  options = list(maxItems = length(CCAA))
                )
            }
        })

        # Select total or selectize Age Groups - Mortality
        output$selectAgeGroupsMortalityUIOutput <- renderUI({
            if (input$selectAgeGroupsMortalityTotal == 'select') {
                selectizeInput("selectAgeMortality",
                  label = h5(strong("Select Age group(s)")),
                  choices = AGE_GROUPS,
                  options = list(maxItems = length(AGE_GROUPS))
                )
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
            shinyjs::show('processingUpdateDatabaseTime')
            updateActionButton(session=session, inputId='updateDatabaseButton', label="Update Database (Again)")
        })

        # log output from command in update database
        output$consoleLogsUpdateDatabase <- renderUI({
            HTML(updateDBLogs())
        })
    } 
)

