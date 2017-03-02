source("dataprep.R")
## Rainfall ##
## Historic mean rainfall for a year (from SABESP site, 2014)
ph.av <- c(259.9 , 202.6, 184.1, 89.3, 83.2, 56.0, 49.9, 36.9, 91.9, 130.8, 161.2, 220.9)
##Rainfall in 2014-2016
## 2016
p.16 <- aggregate(window(cant.dim5$pluv, start="2016-01-01", end="2016-12-31"), as.yearmon, sum)
## 2015
p.15 <- aggregate(window(cant.dim5$pluv, start="2015-01-01", end="2015-12-31"), as.yearmon, sum)
## 2014
p.14 <- aggregate(window(cant.dim5$pluv, start="2014-01-01", end="2014-12-31"), as.yearmon, sum)
## Total average rainfall
sum(ph.av)
## Total average rainfall input (m3 x 1e9)
sum(ph.av)*0.002279493
## Total rainfall 2016
sum(p.16)
## Total rainfall input 2016 (m3 x 1e9)
sum(p.16)*0.002279493
## Total rainfall 2015
sum(p.15)
## Total rainfall input 2015 (m3 x 1e9)
sum(p.15)*0.002279493
## Total rainfall input 2014 (m3 x 1e9)
sum(p.14)*0.002279493

## Inflow ##
## Averages 1930-2015
vazoes <- read.csv2("../data/vazoes_1930_2015.csv", as.is=TRUE)
vazoes <- zoo(vazoes$x, as.yearmon(vazoes$X, format="%b %Y"))
## 1930-2013
v.13 <- window(vazoes, end="Dez 2013")
## Monthly averages
v.13.mean <- aggregate(v.13, by=list(mes=format(time(v.13), "%m")), mean, na.rm=TRUE)
## Number of days o each month (mean number of days of the year from https://en.wikipedia.org/wiki/Leap_year#cite_note-4)
ndays <- c(31, 28.2425, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
## Total average yearly inflow 
(av.inflow <- sum(v.13.mean*24*3600*ndays)/1e9)
## 2016 inflow
(y16.inflow <- sum(window(cant.dim5$afluente, start="2016-01-01", end="2016-12-31"))/1e9)
##2016 outflow
(y16.outflow <- sum(window(cant.dim5$defluente, start="2016-01-01", end="2016-12-31"))/1e9)
## 2015 inflow
(y15.inflow <- sum(window(cant.dim5$afluente, start="2015-01-01", end="2015-12-31"))/1e9)
##2015 outflow
(y15.outflow <- sum(window(cant.dim5$defluente, start="2015-01-01", end="2015-12-31"))/1e9)
## 2014 inflow
(y14.inflow <- sum(window(cant.dim5$afluente, start="2014-01-01", end="2014-12-31"))/1e9)
##2014 outflow
(y14.outflow <- sum(window(cant.dim5$defluente, start="2014-01-01", end="2014-12-31"))/1e9)
## 2004-2013 outflow
(y04.13.outflow <- sum(window(cant.dim5$defluente, end="2013-12-31"))/(1e9*10))
## Average outflow
(x1 <- mean(window(cant.dim5$defluente, end="2013-12-31"))/(3600*24))
(x2 <- mean(window(cant.dim5$defluente, start="2015-01-01", end="2016-12-31"))/(3600*24))
x2/x1
## total outflow 2004-2013
x1*365*3600*24/1e9
x2*365*3600*24/1e9

## Volume in the beggining and end of years
cant.dim5$v.abs[time(cant.dim5)=="2014-01-01"]/1e6
cant.dim5$v.abs[time(cant.dim5)=="2014-12-31"]/1e6
cant.dim5$v.abs[time(cant.dim5)=="2015-01-01"]/1e6
cant.dim5$v.abs[time(cant.dim5)=="2015-12-31"]/1e6
cant.dim5$v.abs[time(cant.dim5)=="2016-01-01"]/1e6
cant.dim5$v.abs[time(cant.dim5)=="2016-12-31"]/1e6


## Checking volume x inflow - outflow
## 2014
(y14.inflow - y14.outflow)*1e3
(as.numeric(cant.dim5$v.abs[time(cant.dim5)=="2014-12-31"]) - as.numeric(cant.dim5$v.abs[time(cant.dim5)=="2014-01-01"]))/1e6
## 2015
(y15.inflow - y15.outflow)*1e3
(as.numeric(cant.dim5$v.abs[time(cant.dim5)=="2015-12-31"]) - as.numeric(cant.dim5$v.abs[time(cant.dim5)=="2015-01-01"]))/1e6
## 2016
(y16.inflow - y16.outflow)*1e3
(as.numeric(cant.dim5$v.abs[time(cant.dim5)=="2016-12-31"]) - as.numeric(cant.dim5$v.abs[time(cant.dim5)=="2016-01-01"]))/1e6


## Eficiency
## 2016
efic2016 <- matrix(
    c( av.inflow, y16.inflow,
      sum(ph.av)*0.002279493-av.inflow, sum(p.16)*0.002279493-y16.inflow),
    byrow=TRUE, ncol=2)

#par(las=1, mar=c(7, 8, 4, 2), mgp=c(5, 2, 0), cex.lab=2, cex.axis=1.5)
#barplot(efic2016, col=c("darkblue", "lightblue"), border=NA, names.arg=c("Média", "2016"), ylab="Volume (bilhões de m3)")
## 2015
efic2015 <- matrix(
    c( av.inflow, y15.inflow,
      sum(ph.av)*0.002279493-av.inflow, sum(p.15)*0.002279493-y15.inflow),
    byrow=TRUE, ncol=2)

#par(las=1, mar=c(7, 8, 4, 2), mgp=c(5, 2, 0), cex.lab=2, cex.axis=1.5)
#barplot(efic2015, col=c("darkblue", "lightblue"), border=NA, names.arg=c("Média", "2015"), ylab="Volume (bilhões de m3)")

efic1516 <- matrix(
    c( av.inflow, y15.inflow, y16.inflow,
      sum(ph.av)*0.002279493-av.inflow, sum(p.15)*0.002279493-y15.inflow, sum(p.16)*0.002279493-y16.inflow),
    byrow=TRUE, ncol=3)

par(las=1, mar=c(7, 8, 4, 2), mgp=c(5, 2, 0), cex.lab=1.5, cex.axis=1.5)
midpoints <- barplot(efic1516, col=c("darkblue", "lightblue"), border=NA, names.arg=c("Média histórica", "2015", "2016"), ylab=expression(paste('Volume (bilhões de m'^'3', ')', sep='')))
text(midpoints[1], c(0.7, 2.5), labels=c('entrada', 'chuva'), cex=1.5, col=c('white', 'black'))

## Exporting data
#write.csv2(as.data.frame(window(cant.dim5, end="2016-12-31"))[,c(1,6,7,4,2)], "dados_2004_20016.csv")
#write.csv2(as.data.frame(v.13), "vazoes_1930_2013.csv")
#write.csv2(data.frame(mes=c("Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"),
#                     pluv=ph.av, ndias=ndays), "pluv_media_sabesp.csv")
