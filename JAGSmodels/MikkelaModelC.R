# Mikkela, A., Ranta, J., Gonz ¨ alez, M., Hakkinen, M., and Tuominen, P. ´ Campylobacter qmra: A bayesian estimation of prevalence and concentration in retail foods under
# clustering and heavy censoring. Risk Analysis 36, 11 (2016), 2065–2080.

model{
  # Prevalence model
  # i = batch, m = month, t = meat type (1 = chicken, 2 = turkey)
  for(i in 1:B[1]){ #+B[2]){
    x[i] ~ dbin(pp[i],n[i]); # model for the positive samples in a batch i
    pp[i] <- I[i]*pw[indt[i]]; # probability of sampling positive sample
    I[i] ~ dbern(pb[indt[i],indm[i]]); # model for the "true contamination status" of a batch i
  }
  
  # Markovian time series for the between-batch prevalence
  for(t in 1){ #:2){
    for(m in 2:12){
      logitpb[t,m] ~ dnorm(logitpb[t,m-1],e[t,m]);
      e[t,m]~ dnorm(0,taue[t]); # model for the difference between consecutive months
    }}
  
  for(t in 1){ #:2){
    for(m in 1:12){
      pb[t,m] <- exp(logitpb[t,m])/(1+exp(logitpb[t,m])); # between-batch prevalence
    }}
  
  for(t in 1){ #:2){
    # pw[t] ~ dunif(0,1); # prior for the within-batch prevalence
    # taue[t] ~ dgamma(0.001,0.001); # prior for the precision (1/variance)
    # logitpb[t,1] ~ dnorm(0,0.001);
    # e[t,1] ~ dnorm(0,0.001);
    pw[t] ~ dunif(prior.pw[t, 1], prior.pw[t, 2]); # prior for the within-batch prevalence
    taue[t] ~ dgamma(prior.taue[t, 1], prior.taue[t, 2]); # prior for the precision (1/variance)
    logitpb[t,1] ~ dnorm(prior.logitpb[t, 1], prior.logitpb[t, 2]);
    e[t,1] ~ dnorm(prior.e[t, 1], prior.e[t, 2]);

  }
  
  # Predictions
  for(t in 1){ #:2){
    for(m in 1:12){
      pf[t,m] <- pw[t]*pb[t,m]; # monthly retail prevalence
    }
    pba[t] <- sum(pb[t,])/12; # average monthly between-batch prevalence
    pfa[t] <- sum(pf[t,])/12; # average monthly retail prevalence
  }
  
  # Concentration model
  
  # j = contaminated batch, k = contaminated sample, t = meat type (1 = chicken, 2 = turkey)
  # hierarchical log-normal model for the positive concentrations
  for(k in 1:34){# exact observations chicken
    logconcentration[k] ~ dnorm(mu[indj[k]],tauw[1]);
  }
  
  for(k in 35:76){# censored observations chicken
    is.censored[k] ~ dinterval(logconcentration[k], c(lower,upper));
    logconcentration[k] ~ dnorm(mu[indj[k]],tauw[1]);
    # logconcentration[k] ~ dnorm(mu[indj[k]],tauw[1])C(lower,upper); #in bugs
  }
  
  # for(k in 77:78){# exact observations turkey
  #   logconcentration[k] ~ dnorm(mu[indj[k]],tauw[2])
  # }
  # 
  # for(k in 79:108){# censored observations turkey
  #   is.censored[k] ~ dinterval(logconcentration[k], c(lower,upper));
  #   logconcentration[k] ~ dnorm(mu[indj[k]],tauw[2]);
  #   # logconcentration[k] ~ dnorm(mu[indj[k]],tauw[2])C(lower,upper)
  # }
  
  ## Batch
  for(j in 1:31){
    mu[j] ~ dnorm(mu_zero[1],taub[1]); # mean concentration in chicken batch j
  }
  
  # for(j in 32:48){
  #   mu[j] ~ dnorm(mu_zero[2],taub[2]); # mean concentration in turkey batch j
  # }
  
  for(t in 1){ #:2){
    # mu_zero[t] ~ dnorm(0,0.001); # prior for the mean concentration in all contaminated batches
    # tauw[t] ~ dgamma(0.001,0.001); # prior for the within-batch precision (1/variance)
    # sdb[t] ~ dunif(0,100); # prior for the between-batch standard deviation
    # taub[t] <- pow(sdb[t],-2); # between-batch precision (1/variance)
    mu_zero[t] ~ dnorm(prior.mu_zero[t, 1],prior.mu_zero[t, 2]); # prior for the mean concentration in all contaminated batches
    tauw[t] ~ dgamma(prior.tauw[t, 1], prior.tauw[t, 2]); # prior for the within-batch precision (1/variance)
    sdb[t] ~ dunif(prior.sdb[t, 1], prior.sdb[t, 2]); # prior for the between-batch standard deviation
    taub[t] <- pow(sdb[t],-2); # between-batch precision (1/variance)
  }
  
  # Predictions
  
  for(t in 1){ #:2){
    murep[t] ~ dnorm(mu_zero[t],taub[t]); # predicted mean concentration in a random 
    # contaminated batch
    log10crep[t] ~ dlnorm(murep[t],tauw[t]); # predicted log10-concentration in a random 
    # contaminated retail meat unit
    #crep[t] <- pow(10,log10crep[t]); # predicted concentration in a random contaminated 
    # retail meat unit
    varb[t] <- 1/taub[t]; # between-batch variance
    varw[t]<- 1/tauw[t]; # within-batch variance
    vartot[t] <- varb[t]+varw[t]; # total variance
    pvarb[t] <- varb[t]/vartot[t]; # proportion of the total variance explained by 
    # between-batch variance
    pvarw[t]<- varw[t]/vartot[t]; # proportion of the total variance explained by 
    # within-batch variance
  }}
