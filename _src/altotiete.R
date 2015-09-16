### R code
### Encoding: UTF-8

###################################################
### R setup
###################################################
library(dplyr)
library(zoo)
library(pomp)
library(caTools)
##source("../suppl2/functions.r")

################################################################################
## Reading and converting data from the SABESP daily bulletins
## http://site.sabesp.com.br/site/interna/Default.aspx?secaoId=553,
## available since 2015-01-15
################################################################################
dados.bol <- read.csv("../data/dados_boletins.csv")
tiete.bol <- dados.bol[dados.bol$sistema=="AltoTiete",-2]
tiete.bol <- zoo(tiete.bol[,-1], as.Date(tiete.bol[,1],"%Y-%m-%d"))
# fixing some bizarre behavior of zoo conversion
if (mode(tiete.bol) == "character"){
    mode(tiete.bol) <- "numeric"
}
# converting from 10^6 m^3 to m^3
tiete.bol$vabs <- 1000000 * tiete.bol$vabs
seg.scaling <- 24*3600 # convertion factor from seconds to days

represas.bol <- read.csv("../data/altotiete.csv")
represas.bol$data <- as.Date(represas.bol$data, format="%Y-%m-%d")

represas.by_date <- group_by(represas.bol, data)
fluxos.at <- summarise(represas.by_date, afluente=sum(afluente), descarregada=sum(descarregada))
tuneis <- summarise(filter(represas.by_date, represa=="B"|represa=="J"), tuneis=sum(tunel))
eeab <- select(filter(represas.bol, represa=="P"), tunel)
fluxos.at$afluente <- seg.scaling * (fluxos.at$afluente - tuneis$tuneis)
fluxos.at$descarregada <- seg.scaling * (fluxos.at$descarregada - eeab$tunel)
fluxos.at$defluente <- fluxos.at$descarregada + seg.scaling * tiete.bol$vazao_anterior

## Running mean of inflow
fluxos.at$afluente.m <- runmean(fluxos.at$afluente, 30, align="right")
fluxos.at.zoo <- zoo(fluxos.at[,-1], fluxos.at$data)
# TODO: 
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

