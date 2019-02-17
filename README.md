# DDP_Irish_Census
Visualisation of Data from Irish Census (2016)

## Introduction
ui.R and server.R form part of the shiny app hosted at  [https://djrobbo83.shinyapps.io/shiny_final_project/](https://djrobbo83.shinyapps.io/shiny_final_project/). The folder /Data contains the data used in the app and this data preparation and cleaning was carried out in the program Data_Preparation_DDP_Irish_Census.R included in the main branch.


## Data Preparation (Data_Preparation_DDP_Irish_Census.R)
**NOTE:** You do not need to run this step to run the Shiny App, see the section *ui.R | server.R: Using the Shiny App Locally* below, however I've included this program for transparency on the transformations applied to the raw census data and also to make my work fully reproducible.

This program describes the steps taken to import the raw irish census data available at: [www.cso.ie](https://cso.ie/en/census/census2016reports/census2016smallareapopulationstatistics/). 

*Please note you will need to set your working directory accordingly if running this program*


### Downloaded Files
A number of files are downloaded from zipped files, but the key ones used in the analysis are:

* Small Area Statistics: **SAPS2016_SA2017.csv** This contains the census statistics for each small area in ireland for each question in the census questionnaire
* Glossary: **SAPS_2016_Glossary.xlsx** This contains a description of the column names which are otherwise not interpretable. This will be used to create the user selections for our Shiny Apps
* Shapefile: **Small_Areas__Generalised_50m__OSi_National_Boundaries.shp** This contains the boundary file for each small area. This is used to calculate the centroid of each small area as an X-Y co-ordinate which will allow us to plot the response of each small area in the appropriate location. We are also able to calculate the area of each small area, and will use this to vary the size of the circle plotted in leaflet - as well as some additional information to make the plots more readable. 

### Output Files: Used in Shiny App
There are 3 files output for use in the shiny app

* **SA_Stats**: This is the SAPS2016_2017.csv file, where all integer columns are converted to a percentage to allow us to compare the observed response in each small area
* **full_gloss_final** : this file is a tidied version of the Glossary file imported, and will be used to populate the drop down user inputs in the final shiny App
* **centroids_final** : this file is a summary taken from the shapefile which includes the X-Y co-ordinates marking the centre of each small area as well as information like County, ED name which will be useful to display on the map when the user hovers over a plotted circle

## ui.R | server.R: Using the Shiny App Locally
If the user would like to use the shiny app locally, the following steps should be taken:

1. Download the ui.R and server.R programs to a folder on your local drive.
2. Within the folder create a subfolder called **/data** and download the .rds files from the folder "/Data" in this repo to this newly created folder
3. Open ui.R and server.R
4. hit "Run App"
5. **NOTE:** You may need to install some of the packages called in ui.R and server.R if you don't already have these installed.

## Purpose of App
This Shiny App allows the user to visualise the response to Census questions published in the results of the Irish 2016 Census. From this we can see which areas have lowest proportion of observed response to highest. This is done via a heat map where blue represents the lowest proportion of a response and red highest - as well as a map a table including the top 50 and bottom 50 small areas are produced to aid the user.  

