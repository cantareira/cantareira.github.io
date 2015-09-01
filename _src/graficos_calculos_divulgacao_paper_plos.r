source("dataprep.R")
library(dplyr)
## Graficos
## Serie temporal do volume e da chuva
Yz <- cant.dim2 %>%
        as.data.frame() %>%
            mutate(inflow.m = runmean(afluente, k=30, align="right")/(24*3600),
                   outflow.m = runmean(defluente, k=30, align="right")/(24*3600)) %>%
                select(v.rel, pluv.m, inflow.m, outflow.m) %>%
                    zoo(time(cant.dim2))

pdf("volume-rain-ts.pdf", width=12, height=5)
par(mar=c(0,7.2,0,6.5), las=1, oma=c(4,4,.5,.5), tcl=-.25, 
    mgp=c(5,1,0), cex.lab=2, cex.axis=1.8, lwd=2.5)
plot(Yz[,"pluv.m"], type="h", col="gray", ylab="", xlab="", axes=FALSE)
par(las=0)
mtext("Chuva (mm)", side=4, line=3.8, cex=2)
par(las=1)
axis(4, at=c(2,6,10, 14))
par(new=TRUE)
plot(Yz[,"v.rel"]-26.9, lwd=3, col="blue", ylab="Volume (%)")
dev.off()
##
pdf("volume-rain-ts_2010-2015.pdf", width=12, height=5)
Yz <- window(Yz, start="2010-01-01")
par(mar=c(0,7.2,0,6.5), las=1, oma=c(4,4,.5,.5), tcl=-.25, 
    mgp=c(5,1,0), cex.lab=2, cex.axis=1.8, lwd=2.5)
plot(Yz[,"pluv.m"], type="h", col="gray", ylab="", xlab="", axes=FALSE)
par(las=0)
mtext("Chuva (mm)", side=4, line=3.8, cex=2)
par(las=1)
axis(4)
par(new=TRUE)
plot(Yz[,"v.rel"]-26.9, lwd=3, col="blue", ylab="Volume (%)")
dev.off()

## Calculos: chuva total por mes
c.pluv.infl.mes <- aggregate(cant.dim2[,c("afluente", "pluv")], as.yearmon, sum)
c.pluv.infl.mes$afluente <- c.pluv.infl.mes$afluente/1e6
c.pluv.infl.mes$v.rel <- aggregate(cant.dim2[,c("v.rel")], as.yearmon, mean)-26.9
plot(c.pluv.infl.mes)
marco <- c.pluv.infl.mes[months(time(c.pluv.infl.mes))=="março"]
jan <- c.pluv.infl.mes[months(time(c.pluv.infl.mes))=="janeiro"]
fev <- c.pluv.infl.mes[months(time(c.pluv.infl.mes))=="fevereiro"]
jan
fev
mar
write.csv(c.pluv.infl.mes, "medias_mensais_divulgacao_paper_plos.csv")
