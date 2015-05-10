library(zoo)
library(pomp)
library(plyr)
library(dplyr)

## Creates a list of zoo windows of fixed length=len (days)
create.win.fl <- function(zoo.obj, len=180){
    j <- as.numeric(diff(range(time(cant.12))))%/%len
    results <- vector(mode="list", length=j)
    results[[1]] <- window(zoo.obj, end=max(time(zoo.obj)), start=max(time(zoo.obj))-(len-1))
    for(i in 2:j){
        w1 <- results[[i-1]]
        t1 <- time(w1)
        if(i<j)
            results[[i]] <- window(zoo.obj, end=min(t1)-1, start=min(t1)-len)
        else
            results[[i]] <- window(zoo.obj, end=min(t1)-1)
    }
    results <- results[j:1]
    names(results) <- sapply(results, function(x) paste(range(time(x)), collapse="-to-"))
    results
}

## Creates a list of zoo windows defined by date in 'times'
create.win <- function(zoo.obj, times, len){
    periods <- length(times)-1
    results <- vector(mode="list", length=periods)
    if(missing(len)){
        for(i in 1:periods){
            results[[i]] <- window(zoo.obj, start=times[i], end=times[i+1]-1)
        }
    }
    else{
        for(i in 1:periods){
            results[[i]] <- window(zoo.obj, start=times[i], end=times[i]+len-1)
        }
    }
    ##results <- results[length(results):1]
    names(results) <- sapply(results, function(x) paste(range(time(x)), collapse="-to-"))
    results
}


## For the 3 -parameter model ##

## Creates a pomp object for a given data series
create.pomp.3p <- function(zoo.obj){
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
    V = rnorm(mu, sigma*V*sqrt(dt));"
    ## time vector
    t1 <- as.numeric(time(zoo.obj))
    t1 <- t1-min(t1)
    ## pomp object with stochastic model
    pomp.obj <- pomp(
        data=data.frame(times=t1,obs=zoo.obj$v.abs),
        times="times",
        t0=0,
        covar=data.frame(
            times=t1,
            chuva=(zoo.obj$pluv.m+0.1),
            defluente=zoo.obj$defluente),
        tcovar=1,
        statenames="V",
        obsnames="obs",
        paramnames=c("a0","a1","a3","dp","sigma"),
        covarnames=c("chuva", "defluente"),
        measurement.model = obs~norm(mean=V,sd=dp),
        skeleton=skel4b,
        rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
        parameter.transform=function(params, ...) exp(params),
        parameter.inv.transform=function(params, ...) log(params)
    )
    return(pomp.obj)
}

## p1 <- pomp(reserv3.12.stc.3p,
##            rprocess=euler.sim(step.fun=Csnippet(skel4b.simC), delta.t=0.1),
##            statenames="V",
##            obsnames="obs",
##            paramnames=c("a0","a1","a3","dp","sigma"),
##            covarnames=c("chuva", "defluente"))


## Fit the 3-parameter model with bsmc2
## using as priors lognormal distribution with parameters taken from another fit
## (for sequential fits as time series are updated)
## if another fit is provided in bsmc2.obj parameters and lognormal priors are taken from it
bsmc2.fit.3p <- function(pomp.obj, params, rpriors, bsmc2.obj, Np=10000, transform=TRUE){
    if(!missing(bsmc2.obj)){
        params <- coef(bsmc2.obj)
        params["V.0"] <- obs(pomp.obj)[1,1]
        post <- bsmc2.obj@post
        if(!bsmc2.obj@transform)
            post <- log(post)
        rpriors <- function(params, ...){
            params["a0"] <- rlnorm(n=1, mean(post["a0",]), sd(post["a0",]))
            params["a1"] <- rlnorm(n=1, mean(post["a1",]), sd(post["a1",]))
            params["sigma"] <- rlnorm(n=1, mean(post["sigma",]), sd(post["sigma",]))
            params
        }
    }
    tmp <- pomp(pomp.obj,
                params=params,
                rprior=rpriors
                )
    bsmc2(tmp, Np=Np, transform=transform)
}

## A function to forecast the fitted stochatic model starting in a given date,
## using a single set of coeficients or a sample from the posterior distribution of coeficients
## p1 is a pomp object and z1 a zoo object with state variables dated, z2 is a zoo object with covars
## all date in z2 should be included in z1
## sim.times = time points at which to simulate, startin with 0 (which corresponds to start)
res.fc <- function(p1, z1, z2, start=min(time(z1)), end=max(time(z1)), deflu,
                   deflu.conv=24*3600, pluv.factor=1,
                   coefs, V.0, nsamp.coef=1, nsim=1000, sim.times, V.max,
                   bounded.vols=TRUE, keep.sims=FALSE, ...){
    coefs <- as.matrix(coefs)
    if(length(time(z1))!=length(time(p1)))
        stop("time lengths differ in pomp and zoo objects")
    if(nsamp.coef > ncol(coefs))
        warning("number of columns in coefs less than nsamp.coef")
    if(!missing(deflu))
       z2$defluente[time(z2)>=start] <- deflu*deflu.conv
    t1 <- zoo(time(p1), time(z1))
    ##t2 <- merge(t1,z2, all=c(FALSE,TRUE))$t1
    t2 <- as.numeric(time(z2)-min(time(p1)))-as.numeric(min(time(z1)))
    p1 <- pomp(
        p1, 
        covar=data.frame(
            times=t2,
            chuva=(z2$pluv.m + 0.05)*pluv.factor,
            defluente=z2$defluente),
        tcovar=1,
        ...
    )
    if(missing(V.0))
        coefs["V.0",] <- as.numeric(z1[time(z1)==start])
    else
        coefs["V.0",] <- V.0
    j <- sample(1:ncol(coefs),nsamp.coef, replace=TRUE)
    t.start <- as.numeric(min(time(p1))+as.Date(start))-as.numeric(min(time(z1)))
    t.end <- as.numeric(min(time(p1))+as.Date(end))-as.numeric(min(time(z1)))
    if(missing(sim.times))
        sim.times <- seq(t.start, t.end)
    else
        sim.times <- t.start + sim.times
    f1 <- function(cfs) {
        pomp::simulate(p1, params=cfs, times=sim.times,
                       nsim=nsim, state=TRUE, as.data.frame=TRUE, t0=t.start)
    }
    sim <- adply(as.matrix(coefs[,j]), 2, f1)
    sim$V2 <- sim$V
    if(bounded.vols){
        sim$V2[is.na(sim$V2)] <- 0
        sim$V2[sim$V2>V.max] <- V.max
    }
    sim.s <-
        sim %>%
            group_by(time) %>%
                summarise(mean=mean(V2, na.rm=TRUE),
                          lower=quantile(V2, 0.025, na.rm=TRUE),
                          upper=quantile(V2, 0.975, na.rm=TRUE),
                          sd= sd(V2, na.rm=TRUE))
    
    sim.s <- zoo(sim.s[,-1], min(time(z1))+sim.times)
    if(keep.sims)
        return(list(sims=sim, obs=z1, summary=sim.s))
    else
        return(list(obs=z1, summary=sim.s))
}

## Forecast for a period ahead
fc.ahead <- function(p1, z1, z2, deflu, pluv.factor=1, ...){
    res.fc(p1=p1, z1=z1,
           z2=z2,
           deflu=deflu,
           pluv.factor=1,
           start=min(time(z2)),
           end=max(time(z2)),
           ...           
           )
}

## Function to plot forecasts generated by function forecast3p
fc.plot <- function(sim, only.obs=FALSE, ci.poly=TRUE, mean.lines=TRUE, ci.lines=FALSE,
                    cpoly=gray.colors(1, alpha=0.3), ...){
    dots <- list(...)
    if(!"ylim" %in% names(dots))
        dots$ylim <- range(c(range(sim$obs),range(sim$summary[,2:3])))
    if(!"col" %in% names(dots))
        dots$col <- "darkblue"
    if(!"lwd" %in% names(dots))
        dots$lwd <- 3
    if(!"ylab" %in% names(dots))
        dots$ylab <- "Stored volume (m3)"
    if(!"xlab" %in% names(dots))
        dots$xlab <-  "Time"
    do.call(plot, c(list(x=sim$obs),dots))
    if(!only.obs){
        if(ci.poly){
            newx <- as.numeric(time(sim$summary))
            y1 <- as.numeric(sim$summary$lower)
            y2 <- as.numeric(sim$summary$upper)
            polygon(c(rev(newx), newx), c(rev(y1),y2), col = cpoly, border = NA)
        }
        if(ci.lines){
            lines(sim$summary$lower, ...)
            lines(sim$summary$upper, ...)
        }
        if(mean.lines)
            if(!"col" %in% names(list(...)))
                dots$col <- "black"
            do.call(lines, c(list(x=sim$summary$mean), dots))
    }
}

## Function to plot lines from forecast generated by function forecast3p
fc.lines <- function(sim, ci.lines=FALSE, mean.lines=TRUE, ci.poly=TRUE,
                     cpoly=gray.colors(1, alpha=0.3), ...){
    if(ci.poly){
        newx <- as.numeric(time(sim$summary))
        y1 <- as.numeric(sim$summary$lower)
        y2 <- as.numeric(sim$summary$upper)
        polygon(c(rev(newx), newx), c(rev(y1),y2), border = NA, col=cpoly)
    }
    if(ci.lines){
        lines(sim$summary$lower, ...)
        lines(sim$summary$upper, ...)
    }
    if(mean.lines)
        lines(sim$summary$mean, ...)
}

## to calculate a variance at a given time in projected simulation
fc.var <- function(p1, z1, z2, deflu, coefs, nsamp.coef=1,
                   start, till=365, ...){
    f1 <-function(st) res.fc(p1=p1, z1=z1, z2=z2, deflu=deflu, coefs=coefs, 
                             start=st, end=as.Date(st)+till,
                             sim.times= as.numeric(min(time(p1))+till+as.Date(st)-as.numeric(min(time(z1)))),
                             ...)$summary
    df1 <- ldply(start, f1)
    zoo(df1, time(z2))
}

### Model-based early signals: whithin-simulation variance of volume in a given time
## provide day date start=end and simulation times in small fractions of time
ews.var <- function(start, pomp, detrend=FALSE, degree=4, ...){
    f1 <- function(y,x, detrent=detrend) {
        if(detrend) {
            m1 <- lm(y~poly((x-min(x)),degree=degree))
            residuals(m1)/(fitted(m1)^2)
        }
        else y
    }
    res.fc(pomp, keep.sims=TRUE, start=start, ...)$sims %>% ##nsim simulates, (bounded) volumes stored in V2
        group_by(sim) %>%
            mutate(V3=f1(V2,x=time)) %>% # polynomial detrending
                group_by(sim) %>%
                    summarise(Vsim=var(V3), # variances of each simulation
                              Csim=sd(V3)/mean(V2),
                              ACF=acf(V3, lag=1, plot=FALSE)[[1]][2,1,1]) %>% 
                                  summarise(
                                      cv.mean=mean(Csim),
                                      cv.sd=sd(Csim),
                                      cv.low95=quantile(Csim, probs=0.025),
                                      cv.up95=quantile(Csim, probs=0.975),
                                      acf.mean=mean(ACF),
                                      acf.sd=sd(ACF),
                                      acf.low95=quantile(ACF, probs=0.025),
                                      acf.up95=quantile(ACF, probs=0.975),
                                      v.mean=mean(Vsim),
                                      v.sd=sd(Vsim),
                                      v.low95=quantile(Vsim, probs=0.025),
                                      v.up95=quantile(Vsim, probs=0.975)
                                  ) 
}

### Utility functions ###

## Improved ls function (http://stackoverflow.com/questions/1358003/tricks-to-manage-the-available-memory-in-an-r-session)
.ls.objects <- function (pos = 1, pattern, order.by,
                        decreasing=FALSE, head=FALSE, n=5) {
    napply <- function(names, fn) sapply(names, function(x)
                                         fn(get(x, pos = pos)))
    names <- ls(pos = pos, pattern = pattern)
    obj.class <- napply(names, function(x) as.character(class(x))[1])
    obj.mode <- napply(names, mode)
    obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
    obj.prettysize <- napply(names, function(x) {
                           capture.output(format(utils::object.size(x), units = "auto")) })
    obj.size <- napply(names, object.size)
    obj.dim <- t(napply(names, function(x)
                        as.numeric(dim(x))[1:2]))
    vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
    obj.dim[vec, 1] <- napply(names, length)[vec]
    out <- data.frame(obj.type, obj.size, obj.prettysize, obj.dim)
    names(out) <- c("Type", "Size", "PrettySize", "Rows", "Columns")
    if (!missing(order.by))
        out <- out[order(out[[order.by]], decreasing=decreasing), ]
    if (head)
        out <- head(out, n)
    out
}

# shorthand
lsos <- function(..., n=10) {
    .ls.objects(..., order.by="Size", decreasing=TRUE, head=TRUE, n=n)
}


## Add an alpha value to a colour (http://www.magesblog.com/2013/04/how-to-change-alpha-value-of-colours-in.html#more)
add.alpha <- function(col, alpha=1){
  if(missing(col))
    stop("Please provide a vector of colours.")
  apply(sapply(col, col2rgb)/255, 2, 
                     function(x) 
                       rgb(x[1], x[2], x[3], alpha=alpha))  
}
