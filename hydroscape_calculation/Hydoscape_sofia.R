##1. Identify points where Ymd<Ypd
##convert date to date format
wp<-read.csv("WP.csv",sep = ";")
summary(wp)
wp$Date<-as.Date(wp$Date,format = "%d/%m/%Y")
class(wp$Date)

##2. if Ymd<Ypd then write 2, if not put 1. (ifelse(comparison, value if true, value if false))
wp$md_vs_pd<-ifelse(wp$WP_MidDay<wp$WP_PreDown,2,1)

##3. take away values with a 2, only keep data with 1 or NA
wp_correct<-wp[wp$md_vs_pd == 1| is.na(wp$md_vs_pd),]
summary(wp_correct)

##5. convert new table to csv
write.csv(wp_correct,"wp_correct.csv")

##4. extract unique dates
unique(wp_correct$Date)

#################Code hydroscape triangle##################################
#1. datasets for each specie
unique(wp_correct$Plot)
MANCHI<-wp_correct[wp_correct$Plot == "MANCHI",]
PACQUI<-wp_correct[wp_correct$Plot == "PACQUI",]
SWIMAC<-wp_correct[wp_correct$Plot == "SWIMAC",]
ACACON<-wp_correct[wp_correct$Plot == "ACACON",]#no data

##########################MANCHI############################################
MANCHI<-wp_correct[wp_correct$Plot == "MANCHI",]
MANCHI$WP_PreDown<-(MANCHI$WP_PreDown)*-1
MANCHI$WP_MidDay<-MANCHI$WP_MidDay*-1

#2. plot with 1:1 line
plot(MANCHI$WP_MidDay~MANCHI$WP_PreDown, 
     xlim=c(0,-1),ylim=c(0,-2))
abline(0, 1, col = "red", lwd = 2, lty = 2)
#3First model
MANCHI_MODEL<-lm(WP_MidDay~WP_PreDown,data=MANCHI,na.action = na.exclude)
summary(MANCHI_MODEL)
abline(MANCHI_MODEL,col = "blue")

#4. select model that maximize r2. Manchi has 128 with a r2 of 0.304
#according to Li, data is selected first close to the 1:1 line. Following Meinzer 
#"Then, starting where Ymin = Ypd, points with less negative Ypd were added until the r2 
#for a linear ﬁt reached its maximum value"
#SELECT POINTS CLOSE TO 1:1 and with small Ypd
#Points closer to 1:1 are the ones in which the difference between Ypd and Ymd is closer to 0

MANCHI$difference<-(MANCHI$WP_PreDown)-(MANCHI$WP_MidDay)
MANCHI_MAX<-MANCHI[MANCHI$difference<0.3| is.na(MANCHI$WP_PreDown) | is.na(MANCHI$WP_MidDay),]

#Following Meinzer, plot from less to more negative Ypd (Si no se corre, se unifica muy lejos
#además valores muy altos de pd son como raros)

MANCHI_MAX<-MANCHI_MAX[MANCHI_MAX$WP_PreDown>(-1)|is.na(MANCHI_MAX$WP_PreDown)| is.na(MANCHI_MAX$WP_MidDay),]
plot(MANCHI_MAX$WP_MidDay~MANCHI_MAX$WP_PreDown,xlim=range(c(0,-5)),ylim=range(c(0,-5)),
     xlab= "Predawn leaf water potential (MPa)",ylab="Midday leaf water potential (MPa)",
     pch=19,main="MANCHI,(r=0.76)",cex=0.5,las=1)
abline(0, 1, col = "red", lwd = 2, lty = 2)

MANCHI_MAX_MODEL<-lm(WP_MidDay~WP_PreDown,data=MANCHI_MAX,na.action = na.exclude)
summary(MANCHI_MAX_MODEL)
abline(MANCHI_MAX_MODEL,col = "blue")

##5. caclulate a (maximun difference between Ypd and Ymd. ie. when Ypd is 0, intercept with y axis)
a<-coef(summary(MANCHI_MAX_MODEL))[1]
a

##6. calculate b (when Ypd=Ymd, point where blue and red cross)
##mx+a=x-> x=a/1-m. Therefore, calculate b and m. b is the intercept (step 5)

m<-coef(summary(MANCHI_MAX_MODEL))[2]
m
b<-(a/(1-m))
b

##7. calculate hydroscape as  (a x b)/2 
MANCHI_AREA<-((a*b)/2)
MANCHI_AREA
#8. number of points 
sum(!is.na(MANCHI_MAX$WP_MidDay))   
sum(!is.na(MANCHI_MAX$WP_PreDown))


#######################################PACQUI##############################
PACQUI<-wp_correct[wp_correct$Plot == "PACQUI",]
PACQUI$WP_PreDown<-PACQUI$WP_PreDown*-1
PACQUI$WP_MidDay<-PACQUI$WP_MidDay*-1
head(PACQUI)
##2. plot data with  1:1 line
plot(PACQUI$WP_MidDay~PACQUI$WP_PreDown,xlim=c(0,-2),ylim=c(0,-2))
abline(0, 1, col = "red", lwd = 2, lty = 2)
##3. first model, R=-0.0081
PACQUI_MODEL<-lm(WP_MidDay~WP_PreDown,data=PACQUI,na.action = na.exclude)
summary(PACQUI_MODEL)
abline(PACQUI_MODEL,col="blue")
##4. find points closer to 1:1 line and higher pd
PACQUI$difference<-(PACQUI$WP_PreDown)-(PACQUI$WP_MidDay)
PACQUI_MAX<-PACQUI[PACQUI$difference>0.3 &  PACQUI$difference<0.5| is.na(PACQUI$WP_PreDown) | is.na(PACQUI$WP_PreDown),]
PACQUI_MAX<-PACQUI_MAX[PACQUI_MAX$WP_PreDown>(-0.8) & PACQUI_MAX$WP_PreDown<(-0.1) | is.na(PACQUI_MAX$WP_PreDown) | is.na(PACQUI_MAX$WP_PreDown),]
##5. plot and model
plot(PACQUI_MAX$WP_MidDay~PACQUI_MAX$WP_PreDown,xlim=range(c(0,-5)),ylim=range(c(0,-5)),
     xlab= "Predawn leaf water potential (MPa)",ylab="Midday leaf water potential (MPa)",
     pch=19,main="PACQUI,(r=0.69)",cex=0.5,las=1)

abline(0, 1, col = "red", lwd = 2, lty = 2)
PACQUI_MAX_MODEL<-lm(WP_MidDay~WP_PreDown,data=PACQUI_MAX,na.action = na.exclude)
summary(PACQUI_MAX_MODEL)
abline(PACQUI_MAX_MODEL,col="blue")
#6 Calculate a value
a<-coef(summary(PACQUI_MAX_MODEL))[1]
a
#7. calculate b value 
m<-coef(summary(PACQUI_MAX_MODEL))[2]
m
b<-(a/(1-m))
b
#8. hydoscape area
PACQUI_AREA<-((a*b)/2)

#9. Number of points 
sum(!is.na(PACQUI_MAX$WP_MidDay))   
sum(!is.na(PACQUI_MAX$WP_PreDown))



########################SWIMAC##############################
SWIMAC<-wp_correct[wp_correct$Plot == "SWIMAC",]
SWIMAC$WP_PreDown<-(SWIMAC$WP_PreDown)*-1
SWIMAC$WP_MidDay<-(SWIMAC$WP_MidDay)*-1
#2. plot with 1:1 line
plot(SWIMAC$WP_MidDay~SWIMAC$WP_PreDown,xlim=c(0,-5),ylim=c(0,-5))
abline(0, 1, col = "red", lwd = 2, lty = 2)
#3. first model (r:0.09)
SWIMAC_MODEL<-lm(WP_MidDay~WP_PreDown,data=SWIMAC,na.action = na.exclude)
summary(SWIMAC_MODEL)
abline(SWIMAC_MODEL,col="blue")

#4. maximize r2 (check where does the majorty of data is)
SWIMAC$difference<-(SWIMAC$WP_PreDown)-(SWIMAC$WP_MidDay)

SWIMAC_MAX<-SWIMAC[SWIMAC$difference>0.5 & SWIMAC$difference<1  | is.na(SWIMAC$WP_PreDown) | is.na(SWIMAC$WP_PreDown),]
SWIMAC_MAX<-SWIMAC_MAX[SWIMAC_MAX$WP_PreDown<(-0.2) & SWIMAC_MAX$WP_PreDown>(-0.8)| is.na(SWIMAC_MAX$WP_PreDown) | is.na(SWIMAC_MAX$WP_PreDown),]

SWIMAC_MAX_MODEL<-lm(WP_MidDay~WP_PreDown,data=SWIMAC_MAX,na.action = na.exclude)
summary(SWIMAC_MAX_MODEL)
plot(SWIMAC_MAX$WP_MidDay~SWIMAC_MAX$WP_PreDown,xlim=range(c(0,-5)),ylim=range(c(0,-5)),
     xlab= "Predawn leaf water potential (MPa)",ylab="Midday leaf water potential (MPa)",
     pch=19,main="SWIMAC,(r=0.73)",cex=0.5,las=1)
abline(SWIMAC_MAX_MODEL,col="blue")
abline(0, 1, col = "red", lwd = 2, lty = 2)

#5caclulate a (máximum difference between Ypd and Ymd. ie. when Ypd is 0, intercept with y axis)
a<-coef(summary(SWIMAC_MAX_MODEL))[1]
a
#6 calculate b (when Ypd=Ymd, point where blue and red cross)
##mx+a=x-> x=a/1-m. Therefore, calculate b and m. b is the intercept (step 5)
m<-coef(summary(SWIMAC_MAX_MODEL))[2]
m
b<-(a/(1-m))
b
##7. calculate hydroscape as  (a x b)/2 
SWIMAC_AREA<-((a*b)/2)
SWIMAC_AREA

#8. number of Points used
sum(!is.na(SWIMAC_MAX$WP_MidDay))   
sum(!is.na(SWIMAC_MAX$WP_PreDown))
###################################################################################################
###############################HYDOSCAPE_POLYGONS####################################################################
#################################################################################################
library(ggplot2)
library(dplyr)
library(sf)
library(sp)
##MANCHI
MANCHI
#1. change format of MANCHI to a Matrix  plot the points. [5 is predown and 6 is midday. 
#The code chull does not read NA therefore they should be taken away from the matrix
MANCHI_matrix<-as.matrix(MANCHI)
MANCHI_matrix<-MANCHI_matrix[complete.cases(MANCHI_matrix), ] #retire NA
MANCHI_matrix<-apply(MANCHI_matrix[,c(5,6)],2, as.numeric) # convert to numbers 
#2 plot 
plot(MANCHI_matrix[,1],MANCHI_matrix[,2],xlim=range(c(0,-2)),ylim=range(c(0,-2)),xlab= "Predawn leaf water potential (MPa)",ylab="Midday leaf water potential (MPa)",
     pch=19,main="MANCHI_polygon",cex=0.5,las=1)
abline(0, 1, col = "red", lwd = 2, lty = 2)
#3. calculate the points of the smallest region that enclose the points (convex hull)
MANCHI_chull_points<-chull(x=MANCHI_matrix[,1], y=MANCHI_matrix[,2])
#4 Conect the points with the first point
MANCHI_chull_points<-c(MANCHI_chull_points,MANCHI_chull_points[1])
#5 calculate the coordinates (values of WP that create the polygon)
MANCHI_chull_coords<-MANCHI_matrix[MANCHI_chull_points,]
#6 draw the polygon 
lines(MANCHI_chull_coords,col="blue")
#7 calculate the area
MANCHI_poly<-Polygon(MANCHI_chull_coords,hole = FALSE)
MANCHI_area_polygon<-MANCHI_poly@area
#PACQUI
PACQUI
#1.convert to matrix and retire NA
PACQUI_matrix<-as.matrix(PACQUI)
PACQUI_matrix<-PACQUI_matrix[complete.cases(PACQUI_matrix),]
PACQUI_matrix<-apply(PACQUI_matrix[,c(5,6)],2,as.numeric)
#2 plot
plot(PACQUI_matrix[,1],PACQUI_matrix[,2],xlim=range(c(0,-2)),ylim=range(c(0,-2)),xlab= "Predawn leaf water potential (MPa)",ylab="Midday leaf water potential (MPa)",
     pch=19,main="PACQUI_polygon",cex=0.5,las=1)
abline(0, 1, col = "red", lwd = 2, lty = 2)
#3 calculate points of the polygon and close it
PACQUI_chull_points<-chull(x=PACQUI_matrix[,1],y=PACQUI_matrix[,2])
PACQUI_chull_points<-c(PACQUI_chull_points,PACQUI_chull_points[1])
#4 calculate the coordinates 
PACQUI_chull_coords<-PACQUI_matrix[PACQUI_chull_points,]
#5 draw the polygons 
lines(PACQUI_chull_coords,col="blue")
#6 calculate the area
PACQUI_poly<-Polygon(PACQUI_chull_coords,hole=FALSE)
PACQUI_area_poly<-PACQUI_poly@area
#SWIMAC
SWIMAC
length(SWIMAC$WP_PreDown)
#1.convert to matrix and retire NA
SWIMAC_matrix<-as.matrix(SWIMAC)
SWIMAC_matrix<-SWIMAC_matrix[complete.cases(SWIMAC_matrix),]
SWIMAC_matrix<-apply(SWIMAC_matrix[,c(5,6)],2,as.numeric)
#2 plot
plot(SWIMAC_matrix[,1],SWIMAC_matrix[,2],xlim=range(c(0,-3)),ylim=range(c(0,-3)),xlab= "Predawn leaf water potential (MPa)",ylab="Midday leaf water potential (MPa)",
     pch=19,main="SWIMAC_polygon",cex=0.5,las=1)
abline(0, 1, col = "red", lwd = 2, lty = 2)
#3 Points of the polygon and close them
SWIMAC_chull_points<-chull(x=SWIMAC_matrix[,1], y=SWIMAC_matrix[,2])
SWIMAC_chull_points<-c(SWIMAC_chull_points,SWIMAC_chull_points[1])
#4 calculate the coordinates (values of WP that create the polygon)
SWIMAC_chull_coords<-SWIMAC_matrix[SWIMAC_chull_points,]
#5 Draw the line
lines(SWIMAC_chull_coords,col="blue")
#6. calculate the area
SWIMAC_poly<-Polygon(SWIMAC_chull_coords,hole=FALSE)
SWIMAC_area_polygon<-SWIMAC_poly@area
