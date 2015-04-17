library(zoo)
library(reshape)
## Chuva
raw.ph <- read.csv("../data/pluv_hist_cantareira.csv", as.is=TRUE)
ph <- zoo(raw.ph[,2:8], raw.ph[,1])
ph.anual <- rowMeans(ph, na.rm=T)
ph.bienal <- anual[-length(anual)] + anual[-1]

## vazoes
## leitura dados de referncai para outorga
## http://arquivos.ana.gov.br/institucional/sof/Renovacao_Outorga/DadosdeReferenciaAcercadaOutorgadoSistemaCantareira.pdf
vaz.ana <- read.csv2("../data/vazoes_1930_2012.csv", as.is=TRUE)
vaz.ana <- vaz.ana[,-14]
vaz.ana <- melt(vaz.ana, id.vars="Ano")
vaz.ana$mes.ano <- paste(vaz.ana$variable,vaz.ana$Ano, sep="/")
vaz.ana <- zoo(vaz.ana$value, as.yearmon(vaz.ana$mes.ano, format="%b/%Y"))
## Serie de vazoes de 2004-2015
## 
vaz.sabesp <- aggregate(cant.dim5$afluente/(24*3600), by=as.yearmon(time(cant.dim5)), mean)
## Conferindo se as medias batem no periodo 2004-2012
plot(vaz.ana)
lines(vaz.sabesp, col="blue") ## ok
## Combina as duas series temporais
vazoes <- c(vaz.ana, window(vaz.sabesp, start="2013-01-01"))
## Exporta para csv
write.csv2(vazoes, "../data/vazoes_1930_2015.csv")
