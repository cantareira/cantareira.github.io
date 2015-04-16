## Preparacao ##
source("dataprep.R")
source("forecast_functions.R") ## funcoes necessarias
c1 <- cant.dim5 %>%
    as.data.frame() %>%
        mutate(afl.s=afluente/(24*3600),
               def.s=defluente/(24*3600),
               v.abs.e9=v.abs/1e9,
               v.morto=rep(.2875, length(time(cant.dim5))))%>%
                   zoo(time(cant.dim5))
## Serie temporal dos ultimos 6 meses
c2.w <- window(cant.dim5, start=max(time(cant.dim5)-180))

## AJUSTE ##
## Objeto do modelo
c2.pomp <- create.pomp.3p(c2.w)
## Ajuste em duas etapas:
## Valores iniciais
guess <- c(a0=11, a1=0.51, a3=0.59, V.0=c2.w$v.abs[1], dp=3.2e7, sigma=3.7e-3)
## Distribuicoes a priori dos parametros a estimar
c2.prior <- function(params,...){
    params["a0"] <- runif(n=1, min=0.1, max=1000)
    params["a1"] <- runif(n=1, min=0.01,max=1)
    params["sigma"] <- runif(n=1, min=0.001,max=0.05)
    params
}
##Ajuste com bayesian filter em duas etapas:
## 1 . 5 mil iteracoes com distribuicoes a priori definidas acima
tmp.bsmc <- bsmc2.fit.3p(c2.pomp, params=guess, rpriors=c2.prior, Np=5000)
## 2 . 30 mil iterações com a priori lognormais com parametros
## obtidos das ditribuicoes posteriores do primeiro ajuste
c2.fit <- bsmc2.fit.3p(c2.pomp, bsmc2.obj=tmp.bsmc, Np=30000)

## PROJECAO ##
## chuva media para os 30 dias seguintes
## Fim do periodo
fim <- max(time(c1))+30
## Adiciona valores de chuva media para o mes seguinte
tmp <- c(c1$pluv, window(pluv.hist$ph.m, start=max(time(c1))+1, end=fim))
tmp2 <- runmean(tmp, k=30, align="right")
ph.next <- window(zoo(data.frame(pluv=tmp, pluv.m=tmp2), time(tmp)), start=max(time(c1)))
ph.next$defluente <- NA
## Escreva aqui a vazao a usar na projecao
## A principio usamos a media dos 30 dias anteriores,
## MAS verificar o limite superior para o mes nas notas tecnicas
## (http://www2.ana.gov.br/Paginas/servicos/outorgaefiscalizacao/sistemacantareira.aspx)
def.max <- mean(window(c1$def.s, start=max(time(c1)-30)))
## Previsoes do modelo para o mes seguinte,
## com 3 cenarios de chuva em relacao a media e a vazao indicada acima
## Previsto para chuva=media historica
pred.100 <- res.fc(p1=c2.pomp, z1=c2.w$v.abs,
                   z2=ph.next,
                   deflu=def.max,
                   pluv.factor=1,
                   start=min(time(ph.next)),
                   end=max(time(ph.next)),
                   coefs=exp(c2.fit@post),
                   V.max=1.2695e9,
                   nsamp.coef=5000,
                   nsim=2, keep.sims=TRUE
                   )
## 75% da media historica de chuvas
pred.75 <- res.fc(p1=c2.pomp, z1=c2.w$v.abs,
                  z2=ph.next,
                  deflu=def.max,
                  pluv.factor=0.75,
                  start=min(time(ph.next)),
                  end=max(time(ph.next)),
                  coefs=exp(c2.fit@post),
                  V.max=1.2695e9,
                  nsamp.coef=5000,
                  nsim=2,
                  keep.sims=TRUE
                  )
## 125% da media historica de chuvas
pred.125 <- res.fc(p1=c2.pomp, z1=c2.w$v.abs,
                   z2=ph.next,
                   deflu=def.max,
                   pluv.factor=1.25,
                   start=min(time(ph.next)),
                   end=max(time(ph.next)),
                   coefs=exp(c2.fit@post),
                   V.max=1.2695e9,
                   nsamp.coef=5000,
                   nsim=2,
                   keep.sims=TRUE
                   )
## Adiciona os previstos ao objeto de dados
p75 <- pred.75$summary/1e9
names(p75) <- paste(names(p75),"75",sep=".")
p100 <- pred.100$summary/1e9
names(p100) <- paste(names(p100),"100",sep=".")
p125 <- pred.125$summary/1e9
names(p125) <- paste(names(p125),"125",sep=".")
c3 <- merge(c1,ph.m=pluv.hist$ph.m, p75,p100,p125)
c3$v.morto[is.na(c3$v.morto)]=rep(.2875, sum(is.na(c3$v.morto)))
## converte previstos em percentual do volume total (Vol armazenado / Vol total * 100)
c3 <- c3%>%
    as.data.frame()%>%
        mutate(v.morto.rel2=v.morto/0.012695,
               mean.75.rel2=mean.75/0.012695,
               lower.75.rel2=lower.75/0.012695,
               upper.75.rel2=upper.75/0.012695,
               mean.100.rel2=mean.100/0.012695,
               lower.100.rel2=lower.100/0.012695,
               upper.100.rel2=upper.100/0.012695,
               mean.125.rel2=mean.125/0.012695,
               lower.125.rel2=lower.125/0.012695,
               upper.125.rel2=upper.125/0.012695) %>%
            zoo(time(c3))
c3 <- na.approx(c3)

## Tabela de projecoes e seus limites ao fim do periodo de 30 dias
tmpw <- c3[time(c3)==max(time(ph.next)),
           c("mean.75.rel2","lower.75.rel2", "upper.75.rel2",
             "mean.100.rel2","lower.100.rel2", "upper.100.rel2",
             "mean.125.rel2","lower.125.rel2", "upper.125.rel2")]
tab.pred.30 <- data.frame(proj=as.numeric(tmpw[,c("mean.75.rel2","mean.100.rel2","mean.125.rel2")]),
                          lower=as.numeric(tmpw[,c("lower.75.rel2","lower.100.rel2","lower.125.rel2")]),
                          upper=as.numeric(tmpw[,c("upper.75.rel2","upper.100.rel2","upper.125.rel2")]),
                          row.names=c("75% da média", "Na média", "125% da média"))

## Tabela de probabilidades de redução de volume
## Funcao para calculo das probabilidades a partir das projecoes
c.prob <- function(obj, ref){
    x <- obj$sims$V2[obj$sims$time==max(obj$sims$time)]
    sum(x<as.numeric(ref))/length(x)
}
## A tabela
## Volume no ultimo dia da serie
V0 <- c2.w$v.abs[time(c2.w)==max(time(c2.w))]
p.probs <- data.frame(
    cenario=c("75% da média", "Na média", "125% da média"),
    probabilidade=c(c.prob(pred.75, V0),
        c.prob(pred.100, V0),
        c.prob(pred.125, V0))*100)

### Projecao para os proximos dias com a previsao metereologica###
### usando chuva prevista pelo boletim diario da sala de situacao da PCJ
### http://www.sspcj.org.br/index.php/boletins-diarios-e-relatorios-telemetria-pcj/boletimdiario
bol.pred <- boletins[boletins$inicio==max(boletins$inicio),]
## N de dias da previsao
bol.n <- as.numeric(bol.pred$fim-bol.pred$inicio+1)
## Series temporal com ponto medio da chuva prevista: (min+max)/2
bol.pluv <- zoo(rep((bol.pred$maximo+bol.pred$minimo)/2, bol.n), seq(bol.pred$inicio,bol.pred$fim, by=1))
## Calculo da media de chuva dos 30 dias anteriores, usado pelo modelo
tmp <- c(c1$pluv, window(bol.pluv, start=max(time(c1)+1)))
tmp2 <- runmean(tmp, k=30, align="right")
## Serie temporal para realizar a projecao pelo modelo
pluv.bol <- window(zoo(data.frame(pluv.m=tmp2, defluente=NA), time(tmp)), start=max(time(c1)), end=bol.pred$fim)
## Calculo da projecao
pred.bol <- res.fc(p1=c2.pomp, z1=c2.w$v.abs,
                   z2=pluv.bol,
                   deflu=def.max,
                   start=min(time(pluv.bol)),
                   end=max(time(pluv.bol)),
                   coefs=exp(c2.fit@post),
                   V.max=1.2695e9,
                   nsamp.coef=5000,
                   nsim=2
                   )
## Tabela com previsao e intervalos de 95% de credibilidade ##
tab.pred.bol <- pred.bol$summary[,1:3]
## Convertendo para percentual do volume máximo
tab.pred.bol <- window(scale(tab.pred.bol, center=FALSE, scale=rep(1.2695e7, 3)), start=max(time(c1))+1)
