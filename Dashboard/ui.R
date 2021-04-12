# IMPORTING LIBRARIES
require(shiny)
require(shinythemes)
require(dplyr)
require(stringr)
library(shinydashboard)

# DATASETS
pop = read.csv('https://raw.githubusercontent.com/dreth/tfm_uc3m/main/data/pop.csv', header=TRUE)
death = read.csv('https://raw.githubusercontent.com/dreth/tfm_uc3m/main/data/death.csv', header=TRUE)

# Options
CCAA <- unique(pop$ccaa)
AGE_GROUPS <- unique(pop$age_group)
SEXES <- unique(pop$sex)


# UI
shinyUI(
  dashboardPage(
    dashboardHeader(title = "Basic dashboard"),
    dashboardSidebar(
      sidebarMenu(
        menuItem("Mortality", tabName = "mortality", icon = icon("stats", lib="glyphicon")),
        menuItem("Widgets", tabName = "widgets", icon = icon("th"))
      )
    ),
    dashboardBody(id='dashboardBody',
      tabItems(
        # First tab content
        tabItem(tabName = "",
          sidebarLayout(
            sidebarPanel(

            ),

            mainPanel(

            )
          )
        ),

        # Second tab content
        tabItem(tabName = "widgets",
          h2("Widgets tab content")
        )
      )
    )
  )
)

