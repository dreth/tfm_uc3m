# IMPORTING LIBRARIES
require(shiny)
require(shinydashboard)
require(shinyjs)

# UI
shinyUI(
  dashboardPage(
    dashboardHeader(title = "Demographic dashboard"),
    dashboardSidebar(
      sidebarMenu(
        # First tab content
        menuItem("Mortality", tabName = "mortality", icon = icon("stats", lib="glyphicon")),

        # Second tab content
        menuItem("Update Database", tabName = "updateDatabase", icon = icon("refresh", lib="glyphicon"))
      )
    ),
    dashboardBody(id='dashboardBody',
      tabItems(
        # First tab content
        tabItem(tabName = "mortality",
          sidebarLayout(
            sidebarPanel(
              selectInput("plotTypeMortality",
                  label = h5(strong("Select content to plot")),
                  choices = MORTALITY_PLOT_TYPE
                ),
              radioButtons("usePlotlyOrGgplotMortality",
                  label = h5(strong("Plotting library")),
                  choices = PLOT_DEVICE_UI_SELECT,
                  selected = 'plotly'
              ),
              radioButtons("selectCCAAMortalityTotal",
                  label = h5(strong("Select CCAAs or Total")),
                  choices = CCAA_UI_SELECT,
                  selected = 'select'
              ),
              uiOutput("selectCCAAMortalityUIOutput"),
              radioButtons("selectAgeGroupsMortalityTotal",
                  label = h5(strong("Select Age group or Total")),
                  choices = AGE_GROUPS_UI_SELECT,
                  selected = 'select'
              ),
              uiOutput("selectAgeGroupsMortalityUIOutput"),
              selectInput("selectSexesMortality",
                  label = h5(strong("Select Sex/Total")),
                  choices = SEXES
                ),
              sliderInput("weekSliderSelectorMortality",
                  label = h5(strong("Select week range to plot")),
                  min = 1,
                  max = 52,
                  value = c(1,52),
                  step = 1
                ),
              sliderInput("yearSliderSelectorMortality",
                  label = h5(strong("Select year range to plot")),
                  min = min(YEAR),
                  max = max(YEAR),
                  value = c(2015, max(YEAR)),
                  step = 1
              ),
              actionButton("plotMortalityButton",
                  label = h5(strong("Generate plot"))
              )
            ),

            mainPanel(
              uiOutput('ggplotOrPlotlyMortalityUIOutput')
            )
          )
        ),

        # Second tab content
        tabItem(tabName = "updateDatabase",
          fluidPage(
            useShinyjs(),
            actionButton("updateDatabaseButton",
                label = h4(strong("Update Database"))
            ),
            br(),
            htmlOutput(outputId = "consoleLogsUpdateDatabase")
          )
        )
      )
    )
  )
)


