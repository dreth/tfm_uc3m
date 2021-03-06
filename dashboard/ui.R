# UI
shinyUI(
  dashboardPage(
    dashboardHeader(title = 'Dashboard'),
    dashboardSidebar(
      sidebarMenu(
      # First tab content
      menuItem('Mortality', tabName = 'mortality', icon = icon('stats', lib='glyphicon')),

      # Second tab content
      menuItem('Maps', tabName = 'maps', icon = icon('map-marker', lib='glyphicon')),

      # Third tab content
      menuItem('Life expectancy', tabName = 'lifeExp', icon = icon('grain', lib='glyphicon')),

      # Fourth tab content
      menuItem('Database Tables', tabName = 'databaseTable', icon = icon('hdd', lib='glyphicon')),

      # Fifth tab content
      menuItem('DB info and update', tabName = 'updateDatabase', icon = icon('refresh', lib='glyphicon')),

      # Sixth tab content
      menuItem('Documentation', tabName = 'docs', icon = icon('info-sign', lib='glyphicon'))
      )
    ),
    dashboardBody(id='dashboardBody',
      tabItems(
        # First tab content
        tabItem(tabName = 'mortality',     
          sidebarLayout(
            sidebarPanel(
              tags$head(includeCSS('./www/styles.css')),
              tags$head(tags$script(src = 'dimension.js')),
              h4(strong('Mortality metrics')),
              h5(strong('Plot parameters')),
              selectInput('plotTypeMortality',
                label = h5(strong('Select content to plot')),
                choices = MORTALITY_PLOT_TYPE
              ),
              radioButtons('usePlotlyOrGgplotMortality',
                label = h5(strong('Plotting library')),
                choices = PLOT_DEVICE_UI_SELECT,
                selected = 'ggplot2'
              ),
              radioButtons('selectCCAAMortalityTotal',
                label = h5(strong('Select CCAAs or Total')),
                choices = CCAA_UI_SELECT,
                selected = 'all'
              ),
              uiOutput('selectCCAAMortalityUIOutput'),
              radioButtons('selectAgeGroupsMortalityTotal',
                label = h5(strong('Select Age group or Total')),
                choices = AGE_GROUPS_UI_SELECT,
                selected = 'all'
              ),
              uiOutput('selectAgeGroupsMortalityUIOutput'),
              selectInput('selectSexesMortality',
                label = h5(strong('Select Sex/Total')),
                choices = SEXES,
                selected = 'T'
              ),
              sliderInput('weekSliderSelectorMortality',
                label = h5(strong('Select week range to plot')),
                min = 1,
                max = 52,
                value = c(1,52),
                step = 1
              ),
              uiOutput('yearSelectorUIOutputMortality'),
              uiOutput('mortalityTextUIOutput'),
              actionButton('plotMortalityButton',
                label = h4(strong('Generate plot'))
              ),
              hr(),
              h4(strong('Download plot')),
              h5(strong('Plot download controls')),
              radioButtons('plotDownloadSizeSelectorMortality',
                label = h5(strong('Predefined or custom image size')),
                choices = DOWNLOAD_SIZE_TOGGLE,
                selected = 'predefined'
              ),
              uiOutput('plotDownloadSizeControlsMortalityUIOutput'),
              uiOutput('plotDownloadSizeControlsMortalityUIOutputNS2'),
              selectInput('plotDownloadFormatMortality',
                label = h5(strong('Select image format')),
                choices = DOWNLOAD_IMAGE_FORMAT,
                selected = 'png'
              ),
              downloadButton('downloadPlotMortality',
                label=h4(strong('Download plot'))
              )
            ),

            mainPanel(
              plotOutput('mortalityPlot'),
              uiOutput('plotlyUIGenMortality')
            )
          )
        ),

        # Second tab content
        tabItem(tabName = 'maps',
          sidebarLayout(
            sidebarPanel(
              useShinyjs(),
              tags$head(includeCSS('./www/styles.css')),
              selectInput('plotMetricMaps',
                label = h5(strong('Select metric to plot')),
                choices = MAPS_PLOT_TYPE
              ),
              radioButtons('plotLibraryMaps',
                label = h5(strong('Select the type of plot to show')),
                choices = PLOT_LIBRARY_MAPS,
                selected = 'leaflet'
              ),
              radioButtons('selectAgeGroupsLifeExpTotalMaps',
                label = h5(strong('Plot life expectancy at birth or otherwise')),
                choices = AGE_GROUPS_UI_SELECT_LE,
                selected = 'at_birth'
              ),
              radioButtons('selectAgeGroupsMapsTotal',
                label = h5(strong('Select Age group or Total')),
                choices = AGE_GROUPS_UI_SELECT,
                selected = 'all'
              ),
              uiOutput('selectAgeGroupsMapsUIOutput'),
              selectInput('selectSexesMaps',
                label = h5(strong('Select Sex/Total')),
                choices = SEXES,
                selected = 'T'
              ),
              uiOutput('weekSliderSelectorUIOutputMaps'),
              uiOutput('yearSelectorUIOutputMaps'),
              uiOutput('mapsTextUIOutput'),
              actionButton('plotMapsButton',
                label = h4(strong('Generate map'))
              ),
              hidden(
              hr(id='mapDataLabels1'),
              h4(id='mapDataLabels2', strong('Data for selected parameters:')),
              tableOutput('mapDataOutput')
              )
            ),

            mainPanel(
              useShinyjs(),
              tags$head(tags$script(src = 'dimension.js')),
              br(),
              uiOutput('leafletMapOutput'),
              plotOutput('ggplot2MapPlot')
            )
          )
        ),

        # Third tab content
        tabItem(tabName = 'lifeExp',
          sidebarLayout(
            sidebarPanel(
              tags$head(includeCSS('./www/styles.css')),
              tags$head(tags$script(src = 'dimension.js')),
              h4(strong('Life expectancy')),
              uiOutput('lifeExpOrTableHeaderUIOutput'),
              radioButtons('showLifeExpPlotOrLifeTable',
                label = h5(strong('Show plot or life table')),
                choices = SHOW_PLOT_OR_LT,
                selected = 'plot'
              ),
              radioButtons('usePlotlyOrGgplotLifeExp',
                label = h5(strong('Plotting library')),
                choices = PLOT_DEVICE_UI_SELECT,
                selected = 'ggplot2'
              ),
              radioButtons('selectCCAALifeExpTotal',
                label = h5(strong('Select CCAAs or Total')),
                choices = CCAA_UI_SELECT,
                selected = 'all'
              ),
              uiOutput('selectCCAALifeExpUIOutput'),
              radioButtons('selectAgeGroupsLifeExpTotal',
                label = h5(strong('Plot life expectancy at birth or otherwise')),
                choices = AGE_GROUPS_UI_SELECT_LE,
                selected = 'at_birth'
              ),
              uiOutput('selectAgeGroupsLifeExpUIOutput'),
              selectInput('selectSexesLifeExp',
                label = h5(strong('Select Sex/Total')),
                choices = SEXES,
                selected = 'T'
              ),
              uiOutput('weekSliderSelectorLifeExpUIOutput'),
              uiOutput('yearSliderSelectorLifeExpUIOutput'),
              uiOutput('lifeExpTextUIOutput'),
              uiOutput('lifeExpButtonUIOutput'),
              hr(),
              uiOutput('lifeExpOrTableDownloadHeaderUIOutput'),
              radioButtons('plotDownloadSizeSelectorLifeExp',
                label = h5(strong('Predefined or custom image size')),
                choices = DOWNLOAD_SIZE_TOGGLE,
                selected = 'predefined'
              ),
              uiOutput('plotDownloadSizeControlsLifeExpUIOutput'),
              uiOutput('plotDownloadSizeControlsLifeExpUIOutputNS2'),
              uiOutput('lifeExpPlotDownloadFormatUIOutput'),
              uiOutput('downloadPlotOrTableUIOutput')
            ),

            mainPanel(
              plotOutput('lifeExpPlot'),
              uiOutput('plotlyUIGenLifeExp'),
              hidden(
                tableOutput('lifeTableOutput')
              )
            )
          )
        ),

        # Fourth tab content
        tabItem(tabName = 'databaseTable',
          sidebarLayout(
            sidebarPanel(
              tags$head(includeCSS('./www/styles.css')),
                # Table filters
                selectInput('selectDBTable',
                label = h5(strong('Select database table to generate')),
                choices = DATABASE_TABLES
                ),
                radioButtons('selectCCAADBTableTotal',
                label = h5(strong('Select CCAAs or Total')),
                choices = CCAA_UI_SELECT,
                selected = 'all'
                ),
                uiOutput('selectCCAADBTableUIOutput'),
                radioButtons('selectAgeGroupsDBTableTotal',
                  label = h5(strong('Select Age group or Total')),
                  choices = AGE_GROUPS_UI_SELECT,
                  selected = 'all'
                ),
                uiOutput('selectAgeGroupsDBTableUIOutput'),
                selectInput('selectSexesDBTable',
                  label = h5(strong('Select Sex/Total')),
                  choices = SEXES,
                  selected = 'T'
                ),
                sliderInput('weekSliderSelectorDBTable',
                  label = h5(strong('Select week range to filter')),
                  min = 1,
                  max = 52,
                  value = c(1,52),
                  step = 1
                ),
                sliderInput('yearSliderSelectorDBTable',
                  label = h5(strong('Select year range to filter')),
                  min = min(YEAR),
                  max = max(YEAR),
                  value = c(min(YEAR), max(YEAR)),
                  step = 1
                ),
                br(),
                downloadButton('downloadDBTable',
                label=h4(strong('Download the filtered data'))
                )    
              ),

            mainPanel(
              wellPanel(
                tags$head(includeCSS('./www/styles.css')),
                # Table display for preview
                dataTableOutput('tableDownloadPreviewDBTable')
              )
            )
          )
        ),

        # Fifth tab content
        tabItem(tabName = 'updateDatabase',
          fluidPage(
            tags$head(includeCSS('./www/styles.css')),
            useShinyjs(),
            wellPanel(
              # GENERAL DB INFO
              h3(strong('Database information:')),
              hr(),
              h4(strong('Last DB update:')),
              verbatimTextOutput('lastUpdatedLog'),
              hr(),
              # DEATHS DB
              h4(strong('Deaths DB (Eurostat):')),
              h5(strong('Latest Eurostat date available:')),
              verbatimTextOutput('lastEurostatWeek'),
              h5(strong('Latest date available in the repository:')),
              verbatimTextOutput('lastEurostatWeekRepo'),
              h5(strong('Data is provisional since:')),
              verbatimTextOutput('provisionalDataIndicator'),
              h5(strong('Original DB ID from Eurostat:')),
              verbatimTextOutput('eurostatDBID'),
              hr(),
              # POP DB
              h4(strong('Population DB (INE):')),
              h5(strong('Latest date available from INE population DB:')),
              verbatimTextOutput('lastINEWeek'),
              h5(strong('Original DB ID from INE:')),
              verbatimTextOutput('INEDBID'),
            ),
            br(),
            wellPanel(
              # UPDATE DB BUTTON
              uiOutput('updateDBButtonUIOutput'),
              hr(),
              h4(strong('Logs:')),
              br(),
              htmlOutput('consoleLogsUpdateDatabase')
            )
          )
        ),

        # Sixth tab content
        tabItem(tabName = 'docs',
          fluidPage(
            tags$head(includeCSS('./www/styles.css')),
            useShinyjs(),
            wellPanel(
              selectInput('docsSectionSelect',
                label = h4(strong('Select section to view documentation')),
                choices = SECTIONS
              )
            ),
            br(),
            wellPanel(
              uiOutput('docsSectionUIOutput')
            )
          )
        )
      )
    )
  )
)