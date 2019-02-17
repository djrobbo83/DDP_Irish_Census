# THIS PROGRAM TAKES RAW CENSUS DATA, MADE FREELY AVAILABLE AT 
# https://cso.ie/en/census/census2016reports/census2016smallareapopulationstatistics/
# AND CREATES 3 DATA SETS TO BE USED IN A SHINY APP WHICH DISPLAYS
# A MAP PLOTTING EACH SMALL AREA IN IRELAND, THE LOWEST LEVEL CENSUS DATA IS AVAILABLE
# PLOTS ARE COLOURED ACCORDING TO RANK USING SPECTRAL PALETTE FROM RCOLORBREWER
# BLUE IS LOW; RED IS HIGH
# THIS ENABLES THE USER TO VISUALISE THE EFFECT OF EACH RESPONSE TO THE CENSUS QUESTIONNAIRE 

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
#
# 0. SET WORKING DIRECTORY
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
# PLEASE SET WORKING DIRECTORY ACCORDINGLY. THIS IS WHERE RAW FILES WILL BE DOWNLOADED TO
# AND FINAL DATASETS SAVED TO
setwd("C:\\Data Science Specialization JHU\\C9_Developing_Data_Products\\Final_Project")

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
#
# 1. PACKAGES REQUIRED
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

library(xlsx)
library(tidyr)
library(zoo)
library(dplyr)
library(rgdal)
library(rgeos)
library(raster)
library(dplyr)
library(leaflet)
library(htmltools)

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
#
# 2. DOWNLOAD RAW DATA TO WORKING DIRECTORY
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

# CENSUS DATA IS STORED AS A ZIP FILE FROM FOLLOWING URL
# THIS IS THE MAIN CENSUS DATA AND CONTAINS 802 COLUMNS
url <- "https://cso.ie/en/media/csoie/census/census2016/census2016boundaryfiles/Saps_2016.zip"
download.file(url, destfile = "./IRL_Census.zip") #UNZIP AND DOWNLOAD FILE
unzip("./IRL_Census.zip")

#ALSO DOWNLOAD SMALL AREA BOUNDARY FILE (.SHP)
# WE CAN USE GENERALISED FILE TO SPEED UP RUN TIME
# THIS WILL GIVE US CO-ORDINATES AT WHICH TO PLOT A POINT FOR EACH SMALL AREA
url <- "http://data-osi.opendata.arcgis.com/datasets/4f55f1a4bcd34e5fb5c8e6e20cadb09e_2.zip"
download.file(url, destfile = "./IRL_Shapefile_50m_G.zip")
unzip("./IRL_Shapefile_50m_G.zip", overwrite = T)

# FINALLY LETS PULL THROUGH THE GLOSSARY TO HELP US IDENTIFY FIELDS OF INTEREST
url <- "https://www.cso.ie/en/media/csoie/census/census2016/census2016boundaryfiles/SAPS_2016_Glossary.xlsx"
download.file(url, destfile = "./SAPS_2016_Glossary.xlsx") #UNZIP AND DOWNLOAD FILE
# NOTE: DOWNLOADING THE FILE ABOVE DOESN'T ALWAYS WORK SUCCESSFULLY SO YOU MAY NEED TO DOWNLOAD AND SAVE TO YOUR
# WORKING DIRECTORY MANUALLY 

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
#
# 3. STANDARDISING THE DATA
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

# THE DATA IS IN INTEGER FORMAT AND THE TOTAL NUMBER OF PEOPLE AND HOUSEHOLDS AND PERSONS IN EACH SMALL AREA IS NOT IDENTICAL
# AS A RESULT WE WILL NEED TO REPRESENT THE RESULTS AS A PERCENTAGE, THEN WE CAN COMPARE EACH SMALL AREA

#FIRST READ IN DATA
SA_Stats <- read.csv("./Saps_2016/SAPS2016_SA2017.csv")
#CREATE A COPY SO WE CAN COMPARE LATER
SA_Stats_Org <- SA_Stats

#READ IN XLSX DESCRIPTION FILE - THIS WILL BE USED FOR DROP DOWNS IN SHINY APP
gloss <- read.xlsx2("./SAPS_2016_Glossary.xlsx", 1)[,3:4] #READ FIRST SHEET FROM FILE; ONLY COLS 3 & 4 ARE USEFUL SO KEEP THESE
full_gloss <- read.xlsx2("./SAPS_2016_Glossary.xlsx", 1)[,1:4] #MIGHT BE USEFUL FOR FILTERING

full_gloss2 <- full_gloss[full_gloss$Tables.Within.Themes != "", ][,1:2] #CREATE A SUBSET OF GLOSSARY KEEPING ROWS IN COLUMN WHICH ISN'T BLANK
full_gloss2$Themes[full_gloss2$Themes == ""] <- NA #REPLACE MISSING VALUES WITH NA SO WE CAN USE na.locf() FUNCTION WHICH COPIES DOWN LAST PREVIOUS VALID VALUE
full_gloss2$Themes <- na.locf(full_gloss2$Themes) #COPY DOWN LAST VALID VALUE
full_gloss2$Table.Name <- lead(full_gloss2$Tables.Within.Themes, 1) 
full_gloss2 <- full_gloss2[c(TRUE, FALSE),] #ONLY KEEP ODD ROWS
#MERGE BACK TO FULL GLOSS
full_gloss_final <- left_join(full_gloss, full_gloss2, by = c("Themes","Tables.Within.Themes")) # JOIN TWO TABLES

full_gloss$Tables.Within.Themes <- gsub("^((?!(Table)).)*$", NA, full_gloss$Tables.Within.Themes, perl = T) #REPLACE ANY STRING STARTING WITH "TABLE" WITH NA
full_gloss$Themes[full_gloss$Themes == ""] <- NA #REPLACE ANY BLANKS WITH NAS
full_gloss$Themes <- na.locf(full_gloss$Themes) # USE na.locf() TO COPY DOWN LAST VALID VALUE
full_gloss$Tables.Within.Themes <- na.locf(full_gloss$Tables.Within.Themes) # USE na.locf() TO COPY DOWN LAST VALID VALUE
full_gloss_final <- left_join(full_gloss, full_gloss2, by = c("Themes","Tables.Within.Themes")) #MERGE TWO DATASETS

#NOW CAN WE IDENTIFY TOTALS?
#full_gloss_final$total_col <- ifelse(grepl("^\\Total", full_gloss_final$Description.of.Field), T, F) #IDENTIFY CENSUS ROWS WHICH ARE TOTALS (NOTE: ONLY USED IN SHINY TO RESTRICT OPTIONS)

#LOOP OVER ALL COLUMNS | TEST IF FACTOR | IF NOT THEN DIVIDE BY NEXT NEAREST TOTAL COLUMN | AS WE MOVE LEFT TO RIGHT
for(i in 4:ncol(SA_Stats)){
  #EXCEPTIONS REQUIRED FOR TABLES ON IRISH LANGUAGE (THEME 3 TABLE 2)- AS NO SUITABLE DENOMINATOR AVAILABLE WITHIN TABLES 
  #ALSO FOR THEME 7 TABLE 1 COMMUNAL ESTABLISHMENTS - NO SUITABLE DENOMINATOR SO USE TOTAL NUMBER OF PEOPLE
  
  #MALE IRISH SPEAKERS: USE TOTAL MALES (COLUMN 38)
  if (i %in% 175:185){
    SA_Stats[,i] <- SA_Stats[,i] / SA_Stats_Org[,38]
  } else if (i %in% 186:196){
    # FEMALE IRISH SPEAKERSL: USE TOTAL FEMALE (COLUMN 73)
    SA_Stats[,i] <- SA_Stats[,i] / SA_Stats_Org[,73]
  } else if (i %in% 197:207){
    # TOTAL IRISH SPEAKERS: USE TOTAL PERSONS (COLUMN 108)
    SA_Stats[,i] <- SA_Stats[,i] / SA_Stats_Org[,108]
  } else if (i %in% 458:459){
    # TOTAL COMMUNAL PROPERTIES AND PEOPLE LIVING IN COMMUNAL PROPERTIES: USE POPULATION TOTAL AS A DENOMINATOR
    SA_Stats[,i] <- SA_Stats[,i] / SA_Stats_Org[,108]
  } else if (class(SA_Stats[,i]) != "factor"){
    #CREATE J TO MAKE IT CLEARER IN FORMULA BELOW
    j = which(full_gloss_final$total_col == T)[[min(which(which(full_gloss_final$total_col == T)+3>=min(i, nrow(full_gloss_final))))]]+3
    SA_Stats[,i] <- SA_Stats[,i] / SA_Stats[,j]
    print(c(i, j)) #CREATED FOR DEBUGGING
  }
  
}

# TESTING - COMMENT OUT
#which(full_gloss_final$total_col == T)[[min(which(which(full_gloss_final$total_col == T)+3>=min(175, nrow(full_gloss_final))))]]+3
#df_test <- data.frame(SA_Stats[,c(175,38)],SA_Stats_Org[,c(175,38)])
# TESTING PASSED

#SAVE DATASETS OUT - SAVE TO GITHUB
# THE ":" seem to be causing a problem - remove using gsub, there is also, unhelpfully some whitespace after the final character
# Which makes it a nightmare to filter on!
full_gloss_final$Themes <- gsub(":", "", full_gloss_final$Themes) #REMOVE ":" FROM STRINGS AS CAUSING ISSUES
full_gloss_final$Themes <- trimws(full_gloss_final$Themes, which = "both") #REMOVE TRAILING BLANKS WHICH LOST ME ABOUT 3 HOURS OF MY LIFE
#CONVERT FACTOR TO CHARACTER
i <- sapply(full_gloss_final, is.factor) 
full_gloss_final[i] <- lapply(full_gloss_final[i], as.character)
#SAVE TO WORKING DIRECTORY
saveRDS(SA_Stats, file = "SA_Stats.Rds")
#saveRDS(SA_Stats_Org, file = "SA_Stats_Integer.Rds") #DON'T NEED THIS FILE FOR ANYTHING LATER
saveRDS(full_gloss_final, file = "full_gloss_final.Rds")

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
#
# 3. READING IN MAP DATA: OUTPUTS REQUIRED --> MAP CENTROIDS
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

#USE readOGR in package rgdal so we can force merge with .csv data
IRL_SA <-readOGR(dsn=".", layer = "Small_Areas__Generalised_50m__OSi_National_Boundaries") #READING IN GENERALISED MAP
IRL_SA@data$id <- rownames(IRL_SA@data)
IRL_SA <- spTransform(IRL_SA, CRS("+proj=longlat +datum=WGS84")) #Converting the UTM coordinates into Latiude and Longitude since leaflet uses those as an argument.
IRL_SA@data$area_sqkm <- area(IRL_SA) # FIND AREA OF SMALL AREA
centroids <- as.data.frame(gCentroid(IRL_SA, byid = TRUE, id = IRL_SA$GUID)) #GET CENTROID.
centroids$GUID <- row.names(centroids) #Adding ID column for the Centroid table.
sq_area <- data.frame(GUID = IRL_SA@data$GUID, area_sqkm = IRL_SA@data$area_sqkm, county = IRL_SA@data$COUNTYNAME, small_area = IRL_SA@data$SMALL_AREA, ED_Name = IRL_SA@data$EDNAME) #PULL OUT ADDITIONAL LABELS

centroids_final <- left_join(centroids, sq_area, by = "GUID") #JOIN CENTROIDS AND SQ_AREA DATASETS TO CREATE FINAL DATASET FOR PLOTTING MAP

saveRDS(centroids_final, file = "centroids_final.Rds")
