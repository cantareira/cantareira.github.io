library(shape)

col3 <- shadepalette("darkblue", "black", n = 50)

nivel <- 0.153 ## ainda falta corrigir pelo angulo do copo
emptyplot(c(-.5,1.5))
filledcylinder(rx = 0.05, ry = 0.29, angle = 90,
               len=nivel,## corrigir aqui pelo angulo do copo
               col = c(col3, rev(col3)), delt=1+(nivel*.3),
               topcol = col3[25],
               mid = c(0.5, nivel/2))  
filledcylinder(rx = 0.05, ry = 0.3, angle = 90, len=1, col = NULL,
                mid = c(0.5, 0.5), lcol = "darkgrey", lwd=8, delt=1.3)          
text(0.5, 1.25, paste(nivel*100,"%", sep=""), cex=4, family="Arial")
text(0.5, -0.25, Sys.Date(), col="darkgrey", cex=1.5, family="Arial")
