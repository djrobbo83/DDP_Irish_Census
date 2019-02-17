#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

centroids_final <- readRDS("data/centroids_final.Rds")
full_gloss_final <- readRDS("data/full_gloss_final.Rds")
SA_Stats <- readRDS("data/SA_Stats.Rds")
#load("F:\\Coursera\\C9_Data_Products\\Course_Project\\full_gloss_final.Rds")
#load("F:\\Coursera\\C9_Data_Products\\Course_Project\\SA_Centroids.Rds")

library(rgdal)
library(rgeos)
library(raster)
library(dplyr)
library(leaflet)
library(htmltools)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

  
   #observeEvent(input$GoButton, {
    #updateTabsetPanel(session, "inTabset",selected = "Map")
  
  
  #OBSERVE FIRST EVENT - USER SELECTING INPUT FROM FIRST DROP DOWN: TABLE NAME
  observeEvent(input$Themes, {
    updateSelectInput(session, "Table_Name",
                      choices = unique(full_gloss_final[full_gloss_final$Themes==input$Themes,]$Table.Name))
  })
  #OBSERVE SECOND EVENT -  USER SELECTING INPUTS FROM SECOND DROP DOWN: TABLE DESCRIPTION
  observeEvent(input$Table_Name, {
    #WANT TO REMOVE TOTALS AS THESE ARE ALL 100% SO ADD NO INSIGHT
    temp_choices_TN <- unique(full_gloss_final[full_gloss_final$Themes==input$Themes &
                                                 full_gloss_final$Table.Name==input$Table_Name,]$Description.of.Field)
    choices_TN <- temp_choices_TN[!grepl("^Total", temp_choices_TN)]
    
    updateSelectInput(session, "Table_Desc",
                      choices = choices_TN)
    
    #updateSelectInput(session, "Table_Desc",
    #                     choices = unique(full_gloss_final[full_gloss_final$Themes==input$Themes & full_gloss_final$Table.Name==input$Table_Name,]$Description.of.Field))
  })
  
  #CREATE TEXT OUTPUT TO DISPLAY BACK TO UI 
  output$Selected_Stat <- renderText({
    paste0("Census Table Name Code: ", full_gloss_final[full_gloss_final$Themes==input$Themes & 
                       full_gloss_final$Table.Name==input$Table_Name &
                          full_gloss_final$Description.of.Field == input$Table_Desc,]$Column.Names[1])
  })
  
  
    output$leaf_plot <- renderLeaflet({
    #Take dependency from GoButton
    if (input$GoButton == 0)
      return()
    
    input$GoButton
    
    
    
    isolate({
      
      keepvar <- full_gloss_final[full_gloss_final$Themes==input$Themes & 
                                    full_gloss_final$Table.Name==input$Table_Name &
                                    full_gloss_final$Description.of.Field == input$Table_Desc,]$Column.Names
      
      SA_Stats_Short <- SA_Stats[c("GUID", keepvar)] 
      
      #MERGE TO CENTROIDS
      SA_Stats_Plot <- left_join(SA_Stats_Short, centroids_final, by = "GUID")
      top50 <- SA_Stats_Plot[order(-SA_Stats_Plot[,2]),][1:50,]
      bottom50 <- SA_Stats_Plot[order(SA_Stats_Plot[,2]),][1:50,]
      
      
        labs <- lapply(seq(nrow(SA_Stats_Plot)), function(i) {
          paste0( '<p>', "Rate: ", round(SA_Stats_Plot[i, keepvar],4)*100, "%", '<p></p>', 
                  "Small Area: ", SA_Stats_Plot[i, "small_area"], '<p></p>', 
                  "County: ", SA_Stats_Plot[i, "county"],'</p><p>', 
                  "Electoral District:", SA_Stats_Plot[i, "ED_Name"], '</p>' ) 
        })
      
      m <- leaflet(SA_Stats_Plot) %>% addTiles() #Assignig Data to leaflet & Add Tiles
      RdYlBu <-colorQuantile("Spectral", domain = unique(SA_Stats_Plot[,2]), n=20,
                             na.color = "#808080", alpha = FALSE, reverse = TRUE, right = FALSE) #Defining the Colorcoding to use.
      
      m %>% addCircles(~x, ~y, radius = ~sqrt(area_sqkm/pi),
                       stroke = FALSE, fillOpacity = 0.70,
                       color = ~RdYlBu(SA_Stats_Plot[,2]),
                       label = lapply(labs, HTML),
                       labelOptions = labelOptions(direction = 'left', opacity = 0.7)) %>% 
        addLegend(pal = RdYlBu, values = ~SA_Stats_Plot[,2], opacity = .5, title = paste0("Quantiles: ", keepvar))
    })
    
  })
  output$top50 <- renderTable({
    #Take dependency from GoButton
    if (input$GoButton == 0)
      return()
    
    input$GoButton
    
    
    
    isolate({
      keepvar <- full_gloss_final[full_gloss_final$Themes==input$Themes & 
                                    full_gloss_final$Table.Name==input$Table_Name &
                                    full_gloss_final$Description.of.Field == input$Table_Desc,]$Column.Names
      
      SA_Stats_Short <- SA_Stats[c("GUID", keepvar)] 
      
      #MERGE TO CENTROIDS
      SA_Stats_Plot <- left_join(SA_Stats_Short, centroids_final, by = "GUID")
      top50 <- SA_Stats_Plot[order(-SA_Stats_Plot[,2]),][1:50,]
      top50
    })
  })
  
  output$bottom50 <- renderTable({
    #Take dependency from GoButton
    if (input$GoButton == 0)
      return()
    
    input$GoButton
    
    isolate({
      keepvar <- full_gloss_final[full_gloss_final$Themes==input$Themes & 
                                    full_gloss_final$Table.Name==input$Table_Name &
                                    full_gloss_final$Description.of.Field == input$Table_Desc,]$Column.Names
      
      SA_Stats_Short <- SA_Stats[c("GUID", keepvar)] 
      
      #MERGE TO CENTROIDS
      SA_Stats_Plot <- left_join(SA_Stats_Short, centroids_final, by = "GUID")
      bottom50 <- SA_Stats_Plot[order(SA_Stats_Plot[,2]),][1:50,]
      bottom50
    })
  })
  

  outputOptions(output, "leaf_plot", suspendWhenHidden = FALSE)
  outputOptions(output, "top50", suspendWhenHidden = FALSE)
  outputOptions(output, "bottom50", suspendWhenHidden = FALSE)

  
})
