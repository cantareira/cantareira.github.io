### R code
### Encoding: UTF-8

###################################################
### R setup
###################################################
library(earlywarnings)
library(zoo)
library(pomp)
library(caTools)
##source("../suppl2/functions.r")
###########################################################
### Reading and transforming data on water volume and rain
## Note: stored water expressed as % of maximum capacity
###########################################################
raw <- read.csv("../data/dados.csv", as.is=TRUE)
## Some corrections
rsp <- raw
## Convert to Date
rsp$data <- as.Date(rsp$data, format="%Y-%m-%d")
## Lines with missing reservoir identity
rsp <- rsp[rsp$manancial!="",]
## Duplicated lines
rsp <- aggregate(rsp[,3:4], by=list(data=rsp$data, manancial=rsp$manancial), mean)
## In Cantareira the usable capacity limit was shift in 18.5% in May 15 2014
## and then in more 10.7% in Oct 23 2014.
z <- rsp$manancial=="sistemaCantareira"
rsp$volume[z&rsp$data>"2014-05-15"] <- rsp$volume[z&rsp$data>"2014-05-15"] - 18.5
rsp$volume[z&rsp$data>"2014-10-23"] <- rsp$volume[z&rsp$data>"2014-10-23"] - 10.7
## In Alto Tiete usable capacity was lowered in Dec 2014
z <- rsp$manancial=="sistemaAltoTiete"
rsp$volume[z&rsp$data>"2014-12-13"] <- rsp$volume[z&rsp$data>"2014-12-13"] - 6.6
### Converting daily time series to zoo object
cant <- rsp[rsp$manancial=="sistemaCantareira",-2]
cant.p <- zoo(x=cant$pluviometria, order.by=cant$data) 
cant <- zoo(x=cant$volume, order.by=cant$data)

###########################################################################
### Reading and preprocessing data on inflow and outflow
###########################################################################
fluxos <- read.csv("../data/data_ocr_cor2.csv", as.is=TRUE)
fluxos$date <- as.Date(fluxos$date, "%Y-%m-%d")
seg.scaling <- 24*3600 # convertion factor from months to seconds
## Inflow
fluxos$afluente <- seg.scaling*apply(
    fluxos[,c("Jaguari_QNat","Cachoeira_QNat","Atibainha_QNat","PaivaC_QNat")], 1, sum)
## Outflow
fluxos$defluente <- seg.scaling*apply(
    fluxos[,c("Jaguari_QJus","Cachoeira_QJus","Atibainha_QJus","PaivaC_QJus", "QESI")], 1, sum)
## Running mean of inflow
fluxos$afluente.m <- runmean(fluxos$afluente, 30, align="right")
fluxos.zoo <- zoo(fluxos[,-1], fluxos$date)
### Converting daily time series to zoo object
## v.rel2= stored volume as a percentage of Total volume (and not of operational volume) 
cant.zoo <- zoo(data.frame(pluv=cant.p, v.rel=cant+29.2, v.rel2=(cant+29.2)*9.8155e6/1269.5e4,
                           v.abs=(cant+29.2)*9.8155e6,
                           pluv.m=runmean(cant.p, 30, align="right")), time(cant))
cant.dim <- merge(cant.zoo, fluxos.zoo[,c("afluente", "defluente", "afluente.m")])
## Croping ends that miss data in one or other series
cant.dim2 <- window(cant.dim, start=min(time(fluxos.zoo)), end=max(time(cant.p)))
## Approximating NA values (few)
cant.dim2 <- na.approx(cant.dim2)
## Eliminating records with extreme outflow outliers
cant.dim5 <- cant.dim2[cant.dim2$defluente<4e6,]
## Selecting data from 2012-2105
cant.12 <- window(cant.dim5, start="2012-01-01")
## Historic mean rainfall for a year (from SABESP site, Feb 2015)
tmp1 <- c(271.1, 199.1, 178, 89.3, 83.2, 56.0, 49.9, 36.9, 91.9, 130.8, 161.2, 220.9)
## Set the starting data of the periodic series: Jan 2012
datas <- as.Date(paste(1,c(2:12,1),rep(c(2013,2014),c(11,1)),sep="-"), format="%d-%m-%Y")-1
## Repeat the data ny years starting in refy and ending in refy2
refy <- as.Date("2004-01-01")
ny <- 12
medias  <- zooreg(data.frame(ph.cum=rep(tmp1,ny), ph.m =rep(tmp1/as.numeric(format(datas, "%d")),ny)),
                  start=as.yearmon(refy), freq=12)
## Average rainfall uniform along each month (montlhy mean repeated over each month) ##
m1 <- zoo(medias, as.Date(time(medias)))
tmp <- merge(m1, zoo(data.frame(y=NA), seq(refy, as.Date(as.yearmon(refy)+ny)-1, by=1)))
pluv.hist1 <- na.locf(tmp[,c("ph.cum","ph.m")])
## Mean of previous 30 days
pluv.hist1$pluv.m30 <- runmean(pluv.hist1$ph.m, k=30, align="right")
## Mean of previous 20 days
pluv.hist1$pluv.m20 <- runmean(pluv.hist1$ph.m, k=20, align="right")
## Mean of previous 10 days
pluv.hist1$pluv.m10 <- runmean(pluv.hist1$ph.m, k=10, align="right")
## Alternative: Interpolate daily values ##
## Set the reference date of the montlhy mean at the middle of each month
m2 <- zoo(medias, as.Date(time(medias))+14)
tmp <- merge(m2, zoo(data.frame(y=NA), seq(refy, as.Date(as.yearmon(refy)+ny)-1, by=1)))
pluv.hist <- na.approx(tmp[,c("ph.cum","ph.m")])
## Mean of previous 30 days
pluv.hist$pluv.m30 <- runmean(pluv.hist$ph.m, k=30, align="right")
## Mean of previous 20 days
pluv.hist$pluv.m20 <- runmean(pluv.hist$ph.m, k=20, align="right")
## Mean of previous 10 days
pluv.hist$pluv.m10 <- runmean(pluv.hist$ph.m, k=10, align="right")

## Rain forecast for the next days ##
## from http://www.sspcj.org.br/index.php/boletins-diarios-e-relatorios-telemetria-pcj/boletimdiario
## boletins <- read.csv("../data/previsoes_boletins_pcj.csv", colClasses=c("Date","Date","numeric"))
boletins <- read.csv("../data/prev_somar.csv", as.is=TRUE)
boletins <- zoo(boletins[,2], as.Date(boletins[,1], "%Y-%m-%d"))

