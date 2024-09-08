source('dataprep.R')

projs <- read.csv('../data/sumario-projecoes.csv')
projs.zoo <- zoo(projs[,3:11], as.Date(projs$data, "%Y-%m-%d")+30)

cant.p.m30 <- zoo(runmean(cant.p, k=30, align="right"), time(cant.p))
all.zoo <- merge.zoo(pluv.hist, projs.zoo, cant.zoo, cant.p.m30, all=FALSE)

pluv.frac <- 100 * all.zoo$cant.p.m30 / all.zoo$pluv.m30

ranges <- matrix(nrow=0, ncol=4)
for (di in time(all.zoo)) {
    d <- as.Date(di)
    # valores de chuva fora dos projetados
    if ((pluv.frac[d] < 62.5) | (pluv.frac[d] > 137.5))
        next
    # valores sabidamente errados
    if ((d >= as.Date("2015-11-16")) & (d <= as.Date("2015-12-6")))
        next

    if (pluv.frac[d] <= 87.5)
        pluv <- "75"
    else if (pluv.frac[d] <= 112.5)
        pluv <- "100"
    else
        pluv <- "125"

    ranges <- rbind(ranges, matrix(c(d, projs.zoo[d,paste("inf", pluv, sep='')],
                                   projs.zoo[d,paste("sup", pluv, sep='')],
                                   cant.zoo$v.rel2[d]), ncol=4))
}
ranges <- zoo(ranges[,2:4], order.by=as.Date(ranges[,1]))
colnames(ranges) <- c("inf", "sup", "obs")
right <- length(which((ranges$obs > ranges$inf) & (ranges$obs < ranges$sup)))
total <- length(time(ranges))
plot(ranges, plot.type='single', col=c("blue","blue","red"))
legend("topleft", colnames(ranges), lty=1, col=c("blue", "blue", "red"))
print(paste("right: ", right, " of ", total, " (", 100*right/total, "%)", sep=''))
