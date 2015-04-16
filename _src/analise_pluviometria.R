library(zoo)

raw.ph <- read.csv("../data/pluv_hist_cantareira.csv", as.is=TRUE)
ph <- zoo(raw.ph[,2:8], raw.ph[,1])
ph.anual <- rowMeans(ph, na.rm=T)
ph.bienal <- anual[-length(anual)] + anual[-1]

