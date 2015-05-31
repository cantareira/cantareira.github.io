library(shape)

## volume do tronco de cone
Vtc <- function(R, r, h) pi*h*(R^2+r^2+R*r)/3
## Volume, dada altura, raio na base e a razão raio maior/menor do copo (parametro delt da funcao de plotagem)
Vtc2 <- function(h, r, delt){
    b <- (delt*r-r)/2
    R <- r + b*(1+h)
    Vtc(R,r,h)
}
## Encontra numericamente a altura para um dado volume
find.h <- function(V, r, delt, min=0, max=1){
    f1 <- function(h) V - Vtc2(h,r,delt)
    uniroot(f1, c(min, max))$root
}
## Volume total
Vtot <- Vtc(0.29,0.29*1.3,1)
find.h(V=Vtot*.15, r=1, delt=1.3)

## Figura: copos com nivel de hoje e de 30 dias
col3 <- shadepalette("darkblue", "black", n = 50)
vm <- find.h(Vtot*.2265, .29, 1.3)
nivel.hoje <- 0.151
alt.h <- find.h(Vtot*nivel.hoje, .29, 1.3)
emptyplot(xlim = c(0,2), ylim = c(-.5,1.5))
filledcylinder(rx = 0.05, ry = 0.29, angle = 90,
               len=alt.h,
               col = c(col3, rev(col3)), delt=1+(alt.h*.3),
               topcol = col3[25],
               mid = c(0.25, nivel.hoje/2))
filledcylinder(rx = 0.05, ry = 0.3, angle = 90, len=1, col = NULL,
               mid = c(0.25, 0.5), lcol = "darkgrey", lwd=8, delt=1.3)
## if(nivel.hoje > 0.23){
##     filledellipse(rx1 = 0.05, ry1 = 0.315, angle = 90,
##                   col = NULL,
##                   mid = c(0.25, vm), lwd=5, lcol="darkgrey",
##                   from=pi/2, to=-pi/2)
## }
## if(nivel.hoje <= 0.23)
##     filledellipse(rx1 = 0.05, ry1 = 0.315, angle = 90,
##                   col = NULL,
##                   mid = c(0.25, vm), lwd=6, lcol="darkgrey")
text(0.25, 1.35, "Hoje", cex=4, family="Arial")
text(0.25, -0.25, paste(round(nivel.hoje*100,1),"%", sep=""), col="darkgrey", cex=3, family="Arial")
## Segundo copo
nivel.30 <- 0.181
alt.30 <- find.h(Vtot*nivel.30, 0.29, 1.3)
filledcylinder(rx = 0.05, ry = 0.29, angle = 90,
               len=alt.30,
               col = c(col3, rev(col3)), delt=1+(alt.30*.3),
               topcol = col3[25],
               mid = c(1.75, nivel.30/2))
filledcylinder(rx = 0.05, ry = 0.3, angle = 90, len=1, col = NULL,
               mid = c(1.75, 0.5), lcol = "darkgrey", lwd=8, delt=1.3)
## if(nivel.30 > 0.23){
##     filledellipse(rx1 = 0.05, ry1 = 0.315, angle = 90,
##                   col = NULL,
##                   mid = c(1.75, vm), lwd=5, lcol="darkgrey",
##                   from=pi/2, to=-pi/2)
## }
## if(nivel.30 <= 0.23)
##     filledellipse(rx1 = 0.05, ry1 = 0.315, angle = 90,
##                   col = NULL,
##                   mid = c(1.75, vm), lwd=6, lcol="darkgrey")
text(1.75, 1.35, "30 dias", cex=4, family="Arial")
text(1.75, -0.25, paste(round(nivel.30*100,1),"%", sep=""), col="darkgrey", cex=3, family="Arial")
text(1, vm*1.3, "Volume morto", col="darkgrey", cex=1.5, family="Arial")
segments(0.56,0.226, 1.41, 0.226, lty=3, lwd=3, col="darkgrey")
