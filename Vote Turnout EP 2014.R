## Visualize the turnout of the 8th European elections (2014)
## 
## Author:    Nicolas Klotz (nicolasklotz.eu)
## Creation:  May 2014
##

# --------- #
# Libraries #
# --------- #

require("plyr")
require("ggplot2")
require("maptools")
require("rgeos")
require("grid")
require("gridExtra")


# -------------- #
# Filemanagement #
# -------------- #
setwd("~/") # change accordingly!
turnout <- read.csv2(file="EP Vote Turnout 1979 - 2009.csv",header=T,sep=";")

source("theme/crayola.R") # Crayola colors: https://gist.github.com/briatte/5813759
source("theme/map_themes.R") # Map theme: https://github.com/briatte/kmaps


# -------------------------- #
# Turnout EP Elections 2014  #
# -------------------------- #

# Groups for giving EU bar a different color
turnout$EU.colour <- 0
turnout$EU.colour[turnout$X=="European Union Total EU"] <- 1
turnout$EU.colour <- as.factor(turnout$EU.colour)

# Plot
plot1 <- ggplot(turnout,
                aes(x=reorder(X, X2014_25.05.14_23.58.CEST), y=X2014_25.05.14_23.58.CEST, # order by turnout
                group=EU.colour, fill=EU.colour)) + # give EU bar a different color
  theme_bw() +
  geom_bar(stat="identity") +
  geom_point(data=turnout, # dots indicating turnout from 2009
                aes(x=reorder(X, X2014_25.05.14_23.58.CEST), y=X2009)) + 
  labs(x="",y="", title="") +
  geom_text(aes(label = sprintf("%1.00f%%", X2014_25.05.14_23.58.CEST), y=X2014_25.05.14_23.58.CEST-2), 
                colour="#ffffff", size = 3) + # display %
  theme(legend.position = "none", # no legend
        axis.text.x  = element_text(angle=45, hjust=1, colour="#000000"), # flip country names
        panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + # no grid lines
  #geom_hline(aes(yintercept=50), colour="#CA2A00", linetype="dashed") + # horizontal line at 50%
  scale_fill_manual(values=c("#1A4876", "#FD5E53")) # color cordes for bars (from crayola.R)


# ----------------------------- #
# Change in turnout (2009-2014) #
# ----------------------------- #

# Calculate difference between 7th and 8th election
turnout$diff78 <- turnout$X2014_25.05.14_23.58.CEST - turnout$X2009

# Groups for giving positive bars a different color than negative ones
turnout$classify <- -1
turnout$classify[turnout$diff78 > 0] <- 1
turnout$classify <- as.factor(turnout$classify)

# Groups indicating left or right labelposition
turnout$label.pos <- 2.5
turnout$label.pos[turnout$diff78 > 0] <- -2.5

# Plot
plot2 <- ggplot(turnout, aes(x=reorder(X, diff78),
                             y=diff78,
                             group=classify, fill=classify)) + 
  geom_bar(stat="identity") + theme_bw() + labs(x="",y="", title="") +
  coord_flip() + # Flip x and y axis
  geom_text(aes(label = sprintf("%1.2f%%", diff78), 
                y=turnout$label.pos, 
                colour=turnout$classify, size = 4)) +
  theme(legend.position = "none",
        panel.grid.minor = element_blank(), 
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = "#000000", linetype = "dotted")) + # dotted lines for every country: increase readability
  scale_y_continuous(limits=c(-25,25)) + # range of y axis (flipped x axis)
  scale_color_manual(values=c("#FD5E53", "#1A4876")) + # color cordes for text (from crayola.R)
  scale_fill_manual(values=c("#FD5E53", "#1A4876")) # color cordes for bars (from crayola.R)


# --------------- #
# Setup Map Data  #
# --------------- #
# Based on:
# - https://github.com/hadley/ggplot2/wiki/plotting-polygon-shapefiles
# - http://f.briatte.org/teaching/ida/100_maps.html
# - http://markuskainu.fi/blog/r-project/2013/11/14/world-values-survey-on-map.html
# Shapefiles:
# - http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_sovereignty.zip
# - http://epp.eurostat.ec.europa.eu/portal/page/portal/gisco_Geographical_information_maps/popups/references/administrative_units_statistical_units_1

# change factor levels that are not ISO2 (Greece!)
turnout$CNTR_ID <- as.character(turnout$CNTR_ID)
turnout$CNTR_ID[turnout$CNTR_ID=="EL"] <- "GR"
turnout$CNTR_ID <- as.factor(turnout$CNTR_ID)

# NaturalEarth Data
#download.file("http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_sovereignty.zip", destfile="ne_10m_admin_0_sovereignty.zip")
#unzip("ne_10m_admin_0_sovereignty.zip",exdir="./naturalearth")
#shape <- readShapeSpatial("./naturalearth/ne_10m_admin_0_sovereignty", proj4string = CRS("+proj=longlat")) # CRS("+proj=robin") for Robinson projection
#shape <- rename(shape, c(ISO_A2 = "CNTR_ID"))

# Eurostat
download.file("http://epp.eurostat.ec.europa.eu/cache/GISCO/geodatafiles/CNTR_2006_03M_SH.zip", destfile="CNTR_2006_03M_SH.zip")
unzip("CNTR_2006_03M_SH.zip",exdir="./eurostat")
shape <- readShapeSpatial("./eurostat/shape/data/CNTR_RG_03M_2006", proj4string = CRS("+proj=longlat")) # CRS("+proj=robin") for Robinson projection

shape@data$id <- rownames(shape@data)
shape.points <- fortify(shape, region = "id")
map.df <- join(shape.points, shape@data, by = "id")
map.df <- join(map.df, turnout, by = "CNTR_ID")

# Plot skeleton
EU.map <- ggplot(map.df) +
  coord_cartesian(xlim = c(-24, 35), ylim = c(34, 72)) + # latitudes and longitudes to display / create map section 
  aes(long, lat, group = group) +
  geom_path(color = "white") +
  geom_polygon() +
  theme_map() # theme from map_themes.R


# ------------------------- #
# Map Turnout EP Elections  #
# ------------------------- #

map.df.missing <- subset(map.df, is.na(X2014_25.05.14_23.58.CEST))
plot3 <- EU.map +
  geom_polygon(data = map.df.missing, aes(long, lat, group = group), fill = "lightgrey") +
  aes(fill = map.df$X2014_25.05.14_23.58.CEST) +
  scale_fill_gradient2("Turnout\n (in %)",
                       low = crayola["Sunset Orange"], high = crayola["Forest Green"], mid = crayola["Yellow"],
                       midpoint = 50,
                       #limits = range(turnout$X2014_25.05.14_23.58.CEST),
                       #breaks = ,
                       na.value = "lightgrey")


# ------------------- #
# Map turnout change  #
# ------------------- #

map.df.missing <- subset(map.df, is.na(diff78))
plot4 <- EU.map +
  geom_polygon(data = map.df.missing, aes(long, lat, group = group), fill = "lightgrey") +
  aes(fill = map.df$diff78) +
  scale_fill_gradient2("Change in turnout\n (in %, 2009-2014)",
                       low = crayola["Sunset Orange"],
                       high = crayola["Forest Green"],
                       mid = crayola["Yellow"],
                       midpoint = 0,
                       #limits = range(turnout$diff78),
                       #breaks = ,
                       na.value = "lightgrey")


# Arrange plots side-by-side 
grid.arrange(plot1, plot3, ncol=2) # Absolute plots: vertical positioning
grid.arrange(plot2, plot4, ncol=2) # Relative plots: vertical positioning