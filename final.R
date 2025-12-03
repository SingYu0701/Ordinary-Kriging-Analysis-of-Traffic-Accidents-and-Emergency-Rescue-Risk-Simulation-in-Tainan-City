library(car)
library(ggplot2)
library(mapview)
library(gstat)
library(sp)
library(sf)
library(raster)
library(dplyr)
library(MASS)
library(pROC)
setwd("C:/Users/s0958/Downloads/gstatfinal")


data = read.csv("11206.csv")
data<-data[,-c(6:8,12:19)]
data <- data[data$GPS經度 > 114, ]
data$GPS經度<-round(data$GPS經度, 2)
data$GPS緯度<-round(data$GPS緯度, 2)
hostpital=read.csv("hostpital.csv")
hostpital$經度<-round(hostpital$經度, 2)
hostpital$緯度<-round(hostpital$緯度, 2)
data_sf <- st_as_sf(data, coords = c("GPS經度", "GPS緯度"), crs = 4326)
hostpital_sf <- st_as_sf(hostpital, coords = c("經度", "緯度"), crs = 4326)

bound = st_read("TOWN_MOI_1120825.shp")
tainan<- bound[bound$COUNTYNAME == "臺南市",]
tainan <- st_transform(tainan, CRS("+init=epsg:3826 +ellps=WGS84"))

ggplot() +
     geom_sf(data = tainan, fill = "lightgray", color = "white") +
     geom_sf(data = hostpital_sf, color = "blue", size = 2, shape = 3) +
     theme_minimal() +
     labs(title = "醫院地點", x = "經度", y = "緯度")

data_aggregated <- data_sf %>%
  group_by(geometry) %>%
  summarize(
    number=n(),
    injuries = sum(X3.2.受傷人數),
    A1 = sum(X3.1.24小時內死亡人數),
    A2=sum(X3.2.2.30日內死亡人數),
    total=sum(X3.2.受傷人數+X3.1.24小時內死亡人數+X3.2.2.30日內死亡人數),
    test=log(number),
    .groups = 'drop'
  )
data_aggregated$type <- ifelse(data_aggregated$A1>0 , 1, 0)

distances <- st_distance(data_aggregated, hostpital_sf)
min_distances <- apply(distances, 1, min)
data_aggregated$distance <- round(min_distances,0)
data<-data_aggregated



#with hostpital
filter_condition <- data$A1 > 0 | data$A2 > 0
filtered_df <- data[filter_condition, ]
fit1<-glm(A1/total ~ distance, family = binomial  ,filtered_df,weights = total)
summary(fit1)
Anova(fit1)
fitted(fit1)
roc<-roc(A1/total ~ fitted(fit1), filtered_df) 
plot.roc(roc, legacy.axes=TRUE)
auc(roc)
filtered_df$prob<-fitted(fit1)
mapview(filtered_df, zcol='prob')
####

# 进行variogram分析

mapview(data, zcol='test')
Var.exp = variogram(test~1, data)
plot(Var.exp)
Var.theo <- vgm(psill=2, "Exp", range=10, nugget=0.8)
plot(Var.exp,Var.theo)
Var.auto <- fit.variogram(Var.exp, Var.theo, fit.sills = TRUE, fit.ranges = TRUE)
plot(Var.exp, Var.auto)

Var.exp2 = variogram(I(prob>0.03)~1,filtered_df)
plot(Var.exp2)
Var.theo2 <- vgm(psill=0.25, "Gau", range=10, nugget=0)
plot(Var.exp2,Var.theo2)
Var.auto2 <- fit.variogram(Var.exp2, Var.theo2, fit.sills = TRUE, fit.ranges = TRUE)
plot(Var.exp2, Var.auto2)

Var.exp1 = variogram(prob~1, filtered_df)
plot(Var.exp1)
Var.theo1 <- vgm(psill=0.0015, "Gau", range=8000, nugget=0.0001)
plot(Var.exp1,Var.theo1)
Var.auto1 <- fit.variogram(Var.exp1, Var.theo1, fit.sills = TRUE, fit.ranges = TRUE)
plot(Var.exp1, Var.auto1)

##################
bound = st_read("TOWN_MOI_1120825.shp")
tainan<- bound[bound$COUNTYNAME == "臺南市",]
tainan <- st_transform(tainan, CRS("+init=epsg:3826 +ellps=WGS84"))

blank_raster<-raster(nrow=100,ncol=100,extent(tainan))
values(blank_raster)<- 1
bound_raster<-rasterize(tainan,blank_raster)
bound_raster[!(is.na(bound_raster))] <- 1
grd_c<-as(bound_raster,"SpatialGridDataFrame")

data_sp <- st_as_sf(data)
data <- as(data_sp, "Spatial")
data <- spTransform(data, CRS(proj4string(grd_c)))

###
data_sp <- st_as_sf(filtered_df)
data <- as(data_sp, "Spatial")
data <- spTransform(data, CRS(proj4string(grd_c)))

###
kriged_c <- krige(test~ 1, data, grd_c, model=Var.theo, nmax=12, nmin=8) # ordinary kriging
spplot(kriged_c["var1.pred"], key.space = "right")
spplot(kriged_c["var1.var"], key.space = "right")

kriged_c1 <- krige(prob~1, data, grd_c, model=Var.theo1, nmax=12, nmin=8) # ordinary kriging
spplot(kriged_c1["var1.pred"], key.space = "right")
spplot(kriged_c1["var1.var"], key.space = "right")
###

###
kriged_c2 <- krige(I(prob>0.03)~1, data, grd_c, model=Var.theo2, nmax=12, nmin=8) # ordinary kriging
spplot(kriged_c2["var1.pred"], key.space = "right")
spplot(kriged_c2["var1.var"], key.space = "right")

mapview(kriged_c2, zcol='var1.pred', na.color="transparent")

# Cross-Validation
# K-fold cross-validation
CV <- krige.cv(test~1, data, Var.theo, nmax = 12, nfold=10)
head(CV)
plot(CV$observed, CV$var1.pred) #plot observed vs. predicted
mean(CV$residual) # mean error, ideally 0
mean(CV$residual^2) # MSPE, ideally small
bubble(CV, "residual", main = "10-fold CV residuals")

# Leave-One-Out
LOO <- krige.cv(test~1, data, Var.theo, nmax = 12, nfold=nrow(data))
head(LOO)
plot(LOO$observed, LOO$var1.pred) #plot observed vs. predicted
Q1 = mean(LOO$residual) # Mean residual ideally near 0
Q2 = mean(LOO$residual^2) # MSPE ideally about 1
cR = exp(mean(log(LOO$var1.var))) # cR as small as possible
hist(LOO$residual) # Are residuals normal?
shapiro.test(LOO$residual)
plot(LOO$var1.pred, LOO$residual) # plot predicted vs. residual (see if locally biased)
cor(LOO$var1.pred, LOO$residual) # correlation predicted and residual, ideally 0
bubble(LOO, "residual", main = "Leave-One-Out CV residuals")

mapview(LOO, zcol='residual', na.color="transparent")
kriged_c$Z<-exp(kriged_c$var1.pred)
mapview(kriged_c, zcol='Z', na.color="transparent")
###########################################################
# Cross-Validation
# K-fold cross-validation
CV <- krige.cv(prob~1, data, Var.theo1, nmax = 12, nfold=10)
head(CV)
plot(CV$observed, CV$var1.pred) #plot observed vs. predicted
mean(CV$residual) # mean error, ideally 0
mean(CV$residual^2) # MSPE, ideally small
bubble(CV, "residual", main = "10-fold CV residuals")

# Leave-One-Out


LOO <- krige.cv(prob~1, data, Var.theo1, nmax = 12, nfold=nrow(data))
head(LOO)
plot(LOO$observed, LOO$var1.pred) #plot observed vs. predicted
Q1 = mean(LOO$residual) # Mean residual ideally near 0
Q2 = mean(LOO$residual^2) # MSPE ideally about 1
cR = exp(mean(log(LOO$var1.var))) # cR as small as possible
hist(LOO$residual) # Are residuals normal?
shapiro.test(LOO$residual)

plot(LOO$var1.pred, LOO$residual) # plot predicted vs. residual (see if locally biased)
cor(LOO$var1.pred, LOO$residual) # correlation predicted and residual, ideally 0
bubble(LOO, "residual", main = "Leave-One-Out CV residuals")

mapview(LOO, zcol='residual', na.color="transparent")

simulated_c <- krige(prob~1, data, grd_c, model=Var.theo1, nmax=12, nmin=8,nsim=4) # ordinary kriging simulation
spplot(simulated_c, key.space = "right")
mapview(simulated_c, na.color="transparent")
