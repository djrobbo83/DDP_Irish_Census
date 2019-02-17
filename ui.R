#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#


library(shiny)
library(rgdal)
library(rgeos)
library(raster)
library(dplyr)
library(leaflet)
library(htmltools)
#load("./SA_Stats.Rda")
centroids_final <- readRDS("data/centroids_final.Rds")
full_gloss_final <- readRDS("data/full_gloss_final.Rds")
SA_Stats <- readRDS("data/SA_Stats.Rds")

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Ireland Census 2016: Results by Small Area"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      #CREATE HELP TEXT FOR APP
      helpText("Create demographic maps with information from the 2016 Ireland Census. 
                Use drop boxes below to select required census statistics.
                Note: These boxes are iterative so please selected from each box in turn top to bottom"),
      #INITIALISE FIRST SELECTION BOX WITH UNIQUE LIST OF NAMES FROM COLUMN NAMED THEMES FROM FULL GLOSS FINAL
      selectInput("Themes", 
                  label = strong("Census Theme"), 
                  choices = unique(full_gloss_final$Themes),
                  selected = "Themes"),
      # INITIALISE INPUTS FOR TABLE NAME (INTERMEDIATE DETAIL) SET AS NULL
      selectInput("Table_Name",
                  label = strong("Census Table"),
                  choices = NULL,
                  selected = "Table_Name"),
      # INITIALISE INPUTS FOR FIELD DESCRIPTION (MOST DETAILED) SET AS NULL
      selectInput("Table_Desc",
                  label = strong("Census Statistic"),
                  choices = NULL,
                  selected = "Table_Desc"),
       # INLCUDE TEXT OUTPUT FROM server.R SO WE CAN DISPLAY NAME OF CENSUS FIELD CODE
       textOutput("Selected_Stat"),
       
       # CREATE ACTION BUTTON TO DELAY GRAPH UPDATE
      actionButton("GoButton", "Click To Update to Selected Data"),
      
      helpText("NOTE: Please Select Map tab before clicking button above as map may appear blank (not rendered). Alternatively,
               if you chose to click the update button while on another tab, on return to Map reclick button above to view map.")
    ),
    
    # FROM DEFAULT EXAMPLE: DELETE OUT
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(type = "tabs", 
      tabPanel("Map", leafletOutput("leaf_plot", width = "100%", height = 800)), #PLAY ABOUT WITH THE HEIGHT HERE
      tabPanel("Table Top 50 Small Areas", tableOutput("top50")),
      tabPanel("Table Bottom 50 Small Areas", tableOutput("bottom50"),
               selected = "Map"))
       #plotOutput("distPlot")
    )
  )
))
