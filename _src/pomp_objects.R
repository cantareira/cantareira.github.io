library(pomp)

## 3 parameter models
################################################################################
## Effect of rain and stored volume for the whole time series
##{
################################################################################
## deterministic Skeleton
skel4b <- function(t,x,params, covars, ...){
    with(as.list(c(x, params, covars)),{
        -defluente + a0*chuva^a1*V^a3
    }
         )
}
## Stochastic Skeleton in C snipet
skel4b.simC <-
"double mu;
mu = V + (-defluente + a0*pow(chuva,a1)*pow(V,a3))*dt;
if(mu<0.) mu=0.;
V = rnorm(mu, sigma*V*sqrt(dt));
"
## time vector
t1 <- as.numeric(time(cant.12))
t1 <- t1-min(t1)
## pomp object with stochastic model
reserv3.12.stc.3p <- pomp(
    data=data.frame(times=t1,obs=cant.12$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(cant.12$pluv.m+0.1),
        defluente=cant.12$defluente,
        afluente=cant.12$afluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)
##}

################################################################################
## Effect of rain for the whole time series
##{
################################################################################
## deterministic Skeleton
skel6 <- function(t,x,params, covars, ...){
    with(as.list(c(x, params, covars)),{
        -defluente + a0*chuva^a1
    }
         )
}
## Stochastic Skeleton in C snipet
skel6.simC <-
"double mu;
mu = V + (-defluente + a0*pow(chuva,a1))*dt;
if(mu<0.) mu=0.;
V = rnorm(mu, sigma*V*sqrt(dt));
"
## time vector
t1 <- as.numeric(time(cant.12))
t1 <- t1-min(t1)
## pomp object with stochastic model
reserv3.12.stc2.3p <- pomp(
    data=data.frame(times=t1,obs=cant.12$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(cant.12$pluv.m+0.1),
        defluente=cant.12$defluente,
        afluente=cant.12$afluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel6,
    rprocess=euler.sim(step.fun=Csnippet(skel6.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)
##}

################################################################################
## Mark Lewis suggestion for the model with effects of Rain and volume:
## additional stochastic term for inflow
##{
################################################################################
skel4c.simC <- "
double mu, Vari;
mu = V + (-defluente + a0*pow(chuva,a1)*pow(V,a3))*dt;
if(mu<0.) mu=0.;
Vari=pow(V,2)*pow(s1,2)+pow(s2,2);
V = rnorm(mu, sqrt(Vari*dt));
"
reserv3.12.stc.3p.3 <- pomp(
    data=data.frame(times=t1,obs=cant.12$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(cant.12$pluv.m+.05),
        defluente=cant.12$defluente,
        afluente=cant.12$afluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","s1","s2"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4c.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)
##}

################################################################################
## 3-parameter model with data window from 13-05-01 to 13-11-01
##{
################################################################################
## Stochastic model
c12.01 <- window(cant.dim5, start="2013-05-01", end="2013-11-01")
## time vector
t1 <- as.numeric(time(c12.01))
t1 <- t1-min(t1)
## pomp object with stochastic model
c12.01.pomp <- pomp(
    data=data.frame(times=t1,obs=c12.01$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(c12.01$pluv.m+0.1),
        defluente=c12.01$defluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)
##}

################################################################################
## 3-parameter model with data window from 13-12-01 to 14-06-01
##{
################################################################################
c12.06 <- window(cant.dim5, start="2013-12-01", end="2014-06-01")
## time vector
t1 <- as.numeric(time(c12.06))
t1 <- t1-min(t1)
## pomp object with stochastic model
c12.06.pomp <- pomp(
    data=data.frame(times=t1,obs=c12.06$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(c12.06$pluv.m+0.1),
        defluente=c12.06$defluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)
##}

################################################################################
## 3-parameter model with data window from 13-07-01 to 14-01-01
##{
################################################################################
c14.01 <- window(cant.dim5, start="2013-07-01", end="2014-01-01")
## time vector
t1 <- as.numeric(time(c14.01))
t1 <- t1-min(t1)
## pomp object with stochastic model
c14.01.pomp <- pomp(
    data=data.frame(times=t1,obs=c14.01$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(c14.01$pluv.m+0.1),
        defluente=c14.01$defluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)

##}

################################################################################
## 3-parameter model with data window from 2013-11-01 to 2014-05-01
##{
################################################################################
c14.05 <- window(cant.dim5, start="2013-11-01", end="2014-05-01")
## time vector
t1 <- as.numeric(time(c14.05))
t1 <- t1-min(t1)
## pomp object with stochastic model
c14.05.pomp <- pomp(
    data=data.frame(times=t1,obs=c14.05$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(c14.05$pluv.m+0.1),
        defluente=c14.05$defluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)

##}

################################################################################
## 3-parameter model with data window from 2014-01-01 to 2014-07-01
##{
################################################################################
c14.07 <- window(cant.dim5, start="2014-01-01", end="2014-07-01")
## time vector
t1 <- as.numeric(time(c14.07))
t1 <- t1-min(t1)
## pomp object with stochastic model
c14.07.pomp <- pomp(
    data=data.frame(times=t1,obs=c14.07$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(c14.07$pluv.m+0.1),
        defluente=c14.07$defluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)

##}

################################################################################
## 3-parameter model with data window from 2014-06-01 to 2014-12-01
##{
################################################################################
c14.12 <- window(cant.dim5, start="2014-06-01", end="2014-12-01")
## time vector
t1 <- as.numeric(time(c14.12))
t1 <- t1-min(t1)
## pomp object with stochastic model
c14.12.pomp <- pomp(
    data=data.frame(times=t1,obs=c14.12$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(c14.12$pluv.m+0.1),
        defluente=c14.12$defluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)

##}

################################################################################
## 3-parameter model with data window from 14-08-1 onwards
##{
################################################################################
c14.08 <- window(cant.dim5, start="2014-08-01")
## time vector
t1 <- as.numeric(time(c14.08))
t1 <- t1-min(t1)
## pomp object with stochastic model
c14.08.pomp <- pomp(
    data=data.frame(times=t1,obs=c14.08$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(c14.08$pluv.m+0.1),
        defluente=c14.08$defluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4b,
    rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)
##}

##4 -parameter models
################################################################################
## 4-parameter model with data window from 14-08-1 onwards
##{
################################################################################
c14.08 <- window(cant.dim5, start="2014-08-01")
## time vector
t1 <- as.numeric(time(c14.08))
t1 <- t1-min(t1)
## pomp object with stochastic model
c14.08.4p.pomp <- pomp(
    data=data.frame(times=t1,obs=c14.08$v.abs),
    times="times",
    t0=0,
    covar=data.frame(
        times=t1,
        chuva=(c14.08$pluv.m+0.1),
        defluente=c14.08$defluente),
    tcovar=1,
    statenames="V",
    obsnames="obs",
    paramnames=c("a0","a1","a2","a3","dp","sigma"),
    covarnames=c("chuva", "defluente"),
    measurement.model = obs~norm(mean=V,sd=dp),
    skeleton=skel4,
    rprocess=euler.sim(step.fun=Csnippet(skel4.simC), delta.t=0.1),
    toEstimationScale=function(params, ...) exp(params),
    fromEstimationScale=function(params, ...) log(params)
)
##}
