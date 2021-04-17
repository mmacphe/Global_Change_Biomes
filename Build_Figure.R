rm(list=ls())

#For uploading large files to GitHub follow these websites:
#https://git-lfs.github.com/
#https://youtu.be/i2XLHvZUXaw

options("rgdal_show_exportToProj4_warnings"="none")
library (rgdal)
library(raster)
library(leaflet)
library(sp)

### Set source directory to the folder this file came from within RStudio
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

### Make a series of mask files based on each global biome
#read in biome 'mask' layer (e.g., Biome1)
Biome1<-readOGR(dsn=paste0('./GlobalBiomes_Shapefiles/BIOME1.shp'))

#read in environmental data layers
precip_2021<-raster('./Climatessp370_GFDL-ESM4/wc2.1_2.5m_prec_GFDL-ESM4_ssp370_2021-2040.tif')
temp_2021<-raster('./Climatessp370_GFDL-ESM4/wc2.1_2.5m_tmin_GFDL-ESM4_ssp370_2021-2040.tif')
precip_change<-raster('./Climatessp370_GFDL-ESM4/bioc12_precip_difference2081-2021.tif')
temp_change<-raster('./Climatessp370_GFDL-ESM4/bioc1_temp_difference2081-2021.tif')

#Make the masked (e.g., Biome1) version of environmental layers (e.g., precip_2021)
#following this website: https://rpubs.com/ricardo_ochoa/416711
Biome1precip_2021<-mask(x=precip_2021, mask=Biome1)
Biome1precip_change<-mask(x=precip_change, mask=Biome1)
Biome1temp_2021<-mask(x=temp_2021, mask=Biome1)
Biome1temp_change<-mask(x=temp_change, mask=Biome1)

#save to Output Files (e.g., Biome1_precip2021.tif)
writeRaster(Biome1precip_2021, filename='./Output Files/Biome1_precip2021.tif', overwrite=TRUE)
writeRaster(Biome1temp_2021, filename='./Output Files/Biome1_temp2021.tif', overwrite=TRUE)
writeRaster(Biome1precip_change, filename='./Output Files/Biome1_precipchange.tif', overwrite=TRUE)
writeRaster(Biome1temp_change, filename='./Output Files/Biome1_tempchange.tif', overwrite=TRUE)

### Build .csv files with both temperature and precipitation for each global biome
#from this website: https://gis.stackexchange.com/questions/278601/extract-values-from-multiple-raster-to-csv
#Note: Repeat the steps below to merge Biome#_precipchange with Biome#_tempchange (not shown below)
r1<-raster('./Output Files/Biome1_precip2021.tif')
library(sf)
aoi_boundary<-st_read('./GlobalBiomes_Shapefiles/BIOME1.shp')
r2<-raster('./Output Files/Biome1_temp2021.tif')

#Extract each pixel value for r1 into a dataframe
r1Extraction<-extract(x=r1,y=as(aoi_boundary,"Spatial"), df=TRUE,cellnumbers=TRUE) 
#this can take >1hr depending on the size of the raster. Use system.time() if want to check how long more precisely to budget your time.

##create a data frame with the coordinates of each cell
r1Coords<-as.data.frame(xyFromCell(r1,r1Extraction[,2]))

#bind the coordinates with te values of the cell
r1Final<-cbind(r1Coords,r1Extraction[,3])

#Extract each pixel value for r2 into a data frame
r2Extraction<-extract(x=r2,y=as(aoi_boundary,"Spatial"),df=TRUE, cellnumbers=TRUE)

#bind the extraction to the r1Final data frame
finalData<-cbind(r1Final,r2Extraction[,3])
head(finalData)

#change the column names to what you want
colnames(finalData)<-c("X", "Y", "precip", "temp")
#add a column for Biome number
finalData$Biome<-'Biome1'

head(finalData)

#save as .csv
write.csv(finalData, file="./Output Files/Biome1_preciptemp2021.csv",row.names=FALSE)

#########################################
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/#
##Repeat the above steps for each Biome##
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/#
#########################################
### Build figure

#bring in all .csv files (e.g., for Biome#_preciptemp2021)
Biome1data<-read.csv('./Output Files/Biome1_preciptemp2021.csv')
Biome2data<-read.csv('./Output Files/Biome2_preciptemp2021.csv')
Biome3data<-read.csv('./Output Files/Biome3_preciptemp2021.csv')
Biome4data<-read.csv('./Output Files/Biome4_preciptemp2021.csv')
Biome5data<-read.csv('./Output Files/Biome5_preciptemp2021.csv')
Biome6data<-read.csv('./Output Files/Biome6_preciptemp2021.csv')
Biome7data<-read.csv('./Output Files/Biome7_preciptemp2021.csv')
Biome8data<-read.csv('./Output Files/Biome8_preciptemp2021.csv')
Biome9data<-read.csv('./Output Files/Biome9_preciptemp2021.csv')
Biome10data<-read.csv('./Output Files/Biome10_preciptemp2021.csv')
Biome11data<-read.csv('./Output Files/Biome11_preciptemp2021.csv')
Biome12data<-read.csv('./Output Files/Biome12_preciptemp2021.csv')
Biome13data<-read.csv('./Output Files/Biome13_preciptemp2021.csv')
Biome14data<-read.csv('./Output Files/Biome14_preciptemp2021.csv')

#merge data frames (stacked) for Temperate and Tropical Biomes (e.g., Biome#_preciptemp2021 data)
Tropical<-rbind(Biome14data,Biome13data,Biome12data,Biome7data,
                Biome3data,Biome2data,Biome1data)
Temperate<-rbind(Biome11data,Biome10data,Biome8data,Biome6data,
                 Biome5data,Biome4data,Biome9data)

#Change Biome numbers to their names
Temperate$Biome<-gsub('Biome10','Montane Grasslands and Shrublands',Temperate$Biome)
Temperate$Biome<-gsub('Biome11','Tundra',Temperate$Biome)
Tropical$Biome<-gsub('Biome12','Mediterranean Forests, Woodlands, and Scrubland',Tropical$Biome)
Tropical$Biome<-gsub('Biome13','Deserts and Xeric Shrublands',Tropical$Biome)
Tropical$Biome<-gsub('Biome14','Mangrove',Tropical$Biome)

Tropical$Biome<-gsub('Biome1','Tropical and Subtropical Moist Broadleaf Forest',Tropical$Biome)
Tropical$Biome<-gsub('Biome2','Tropical and Subtropical Dry Broadleaf Forest',Tropical$Biome)
Tropical$Biome<-gsub('Biome3','Tropical and Subtropical Coniferous Forest',Tropical$Biome)
Temperate$Biome<-gsub('Biome4','Temperate Broadleaf and Mixed Forest',Temperate$Biome)
Temperate$Biome<-gsub('Biome5','Temperate Coniferous Forest',Temperate$Biome)
Temperate$Biome<-gsub('Biome6','Boreal Forest/Taiga',Temperate$Biome)
Tropical$Biome<-gsub('Biome7','Tropical and Subtropical Grasslands, Savannas, and Shrublands',Tropical$Biome)
Temperate$Biome<-gsub('Biome8','Temperate Grasslands, Savannas, and Shrublands',Temperate$Biome)
Temperate$Biome<-gsub('Biome9','Flooded Grasslands and Savannas',Temperate$Biome)

#write to .csv
write.csv(Tropical,file='./Output Files/TropicalBiomesNamed2021.csv',row.names=FALSE)
write.csv(Temperate,file='./Output Files/TemperateBiomesNamed2021.csv',row.names=FALSE)

### Build figure that shows the climographs for each biome and their project change
#following this website to make figure: https://stackoverflow.com/questions/25985159/r-how-to-3d-density-plot-with-gplot-and-geom-density
library(ggplot2)
library(dplyr)
library(ggalt)
library(ggforce)
library(concaveman)
library(ggpubr)

#bring in the data frames omitting pixels with missing data
Temperate<-read.csv('./Output Files/TemperateBiomesNamed2021.csv') %>% na.omit()
Tropical<-read.csv('./Output Files/TropicalBiomesNamed2021.csv') %>% na.omit()

Temperate2<-read.csv('./Output Files/TemperateBiomesChangeNamed.csv') %>% na.omit()
Tropical2<-read.csv('./Output Files/TropicalBiomesChangeNamed.csv') %>% na.omit()

#name each plot
a<-ggplot(Temperate, aes(x=temp,y=precip, color=Biome)) +
  geom_mark_hull(expand=0.01) +
  theme_bw() + 
  theme(panel.border = element_blank(), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line = element_line(colour = "black")) +
  theme(legend.position = c(0.22, 0.75)) +
  theme(legend.title=element_blank(), 
        legend.text=element_text(size=10))

b<-ggplot(Tropical, aes(x=temp,y=precip, color=Biome)) +
  geom_mark_hull(expand=0.01) +
  theme_bw() + 
  theme(panel.border = element_blank(), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line = element_line(colour = "black")) +
  theme(legend.position = c(0.22, 0.65)) +
  theme(legend.title=element_blank(), 
        legend.text=element_text(size=10))

c<-ggplot(Temperate2, aes(x=temp,y=precip, color=Biome)) +
  geom_mark_hull(expand=0.01) +
  geom_vline(xintercept = 0, color = "black", linetype = "dashed", size = 1.5) +
  geom_hline(yintercept=0, color="black", linetype="dashed", size=1.5) +
  theme_bw() + 
  theme(panel.border = element_blank(), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line = element_line(colour = "black")) +
  theme(legend.position="none")

d<-ggplot(Tropical2, aes(x=temp,y=precip, color=Biome)) +
  geom_mark_hull(expand=0.01) +
  geom_vline(xintercept = 0, color = "black", linetype = "dashed", size = 1.5) +
  geom_hline(yintercept=0, color="black", linetype="dashed", size=1.5) +
  theme_bw() + 
  theme(panel.border = element_blank(), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line = element_line(colour = "black")) +
  theme(legend.position="none")

#build the composite figure
png(file='./Output Files/GlobalBiomes.png',width=6.5,height=5.5,units="in",res=500)
ggarrange(a,b,c,d, +rremobe("x.text"),labels=c("A","B","C","D"),ncol=2,nrow=2)
dev.off()
