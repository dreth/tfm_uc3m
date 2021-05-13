# UI
shinyUI(
  dashboardPage(
    dashboardHeader(title = "Dashboard"),
    dashboardSidebar(
      sidebarMenu(
        # First tab content
        menuItem("Mortality", tabName = "mortality", icon = icon("stats", lib="glyphicon")),

        # Second tab content
        menuItem("Update Database", tabName = "updateDatabase", icon = icon("refresh", lib="glyphicon")),

        # Third tab content
        menuItem("Database Tables", tabName = "databaseTable", icon = icon("hdd", lib="glyphicon"))
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
                  selected = 'ggplot2'
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
              br(),
              h5(strong("Last DB update:")),
              uiOutput('lastUpdatedLogMortality')
            ),

            mainPanel(
              plotOutput(outputId = "mortalityPlot"),
              uiOutput('plotlyUIGenMortality'),
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
        ),

        # Third tab content
        tabItem(tabName = "databaseTable",
          fluidPage(
            wellPanel(
              # Table filters
              selectInput("selectDBTable",
                label = h5(strong("Select database table to generate")),
                choices = DATABASE_TABLES
              ),
              radioButtons("selectCCAADBTableTotal",
                label = h5(strong("Select CCAAs or Total")),
                choices = CCAA_UI_SELECT,
                selected = 'all'
              ),
              uiOutput("selectCCAADBTableUIOutput"),
              radioButtons("selectAgeGroupsDBTableTotal",
                  label = h5(strong("Select Age group or Total")),
                  choices = AGE_GROUPS_UI_SELECT,
                  selected = 'all'
              ),
              uiOutput("selectAgeGroupsDBTableUIOutput"),
              selectInput("selectSexesDBTable",
                  label = h5(strong("Select Sex/Total")),
                  choices = SEXES,
                  selected = 'T'
              ),
              sliderInput("weekSliderSelectorDBTable",
                  label = h5(strong("Select week range to filter")),
                  min = 1,
                  max = 52,
                  value = c(1,52),
                  step = 1
              ),
              sliderInput("yearSliderSelectorDBTable",
                  label = h5(strong("Select year range to filter")),
                  min = min(YEAR),
                  max = max(YEAR),
                  value = c(min(YEAR), max(YEAR)),
                  step = 1
              ),
              br(),
              downloadButton("downloadDBTable",
                label=h4(strong("Download the filtered data"))
              )
            )
          )
        )
      )
    )
  )
)


