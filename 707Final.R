
library("ggplot2")
library("gridExtra")
library("dplyr")
library("faraway")
library("MASS")
library("pls")
library("glmnet")
library("class")


setwd("/Users/naeemnowrouzi/Desktop")
bike.data0 <- read.csv("~/Desktop/NAEEM/hour2.csv")
dim(bike.data0)
bike.data <- bike.data0[,-c(2,3,15)] # remove the total count, date, and id variables. 
dim(bike.data) # Check data dimension. 
sum(is.na(bike.data)) 
str(bike.data)
summary(bike.data)
pairs(casual~.,bike.data)

# Check the correlation matrix
cor(bike.data)

# We checked the correlation matrix (not included here) and there are some mild and a few strong correlations between the
# variables. The cor() function uses the Pearson correlation coefficient which is a measure of linear dependence. For
# instance, in the case of our response variable  "casual", the first three  largest correlation coefficients correspond to
# the variables "registered", and the two measurements of temperature(atemp for the "feels like" temperature). These
# coefficients are,  

col.names <- names(bike.data)[order(cor(bike.data)["casual",], decreasing = T)][2:4]
cor(bike.data)["casual", c(col.names)]


# All three coefficients are positive. Intuitively this makes sense. As the number of bikes being used by registered
# customers increases, we expect the number of non-registered customers to increase as well. Though this may not necessarily
# be the case. Same for temperature, as the weather gets warmer, we expect to see more bikes being used. An example of
# negative correlation is with humidity in which case the number of bikes used decreases when humidity increases. It is also
# natural to believe that the response should be strongly correlated to the day and hour, but this does not seem to be
# properly reflected in the correlation matrix perhaps due to presence of a non-linear relationship. We check some of the
# more revealing plots of our response against some of the seemingly important variables  

# Plots
p1 <- ggplot(bike.data, aes(x=registered,y=casual), color)+
  geom_point(alpha=0.05) + facet_grid(~workingday) + 
  ggtitle("0 = non-working day, 1 = working day") + 
  theme(plot.title = element_text(size=10))

p2 <- ggplot(bike.data, aes(x=temp,y=casual), color)+
  geom_point(alpha=0.05) + facet_grid(~workingday) +
  ggtitle("0 = non-working day, 1 = working day")+ 
  theme(plot.title = element_text(size=10))

p3 <- ggplot(bike.data, aes(x=hr,y=casual))+
  geom_point(alpha=0.03) + facet_grid(~weathersit) +
  ggtitle("Weather Condition from 1 to 4")+ 
  theme(plot.title = element_text(size=10))

p4 <- ggplot(bike.data, aes(x=hr,y=casual))+
  geom_point(alpha=0.03) + facet_grid(~workingday) +
  ggtitle("0 = non-working day, 1 = working day")+ 
  theme(plot.title = element_text(size=10))
grid.arrange(p1, p2, p3, p4)  


# We particularly observe the importance of hour, weather condition, and whether or not it's a working day on the rental
# counts. From the top left plot it seems that on a non-working day there is a more pronounced linear relationship between
# rental counts for subscribers and for non-subscribers. On a working day, no clear-cut relationsihp is visible.   


# It seems in general the rental count for non-subscribers is higher on non-working days, and for subscribers it is higher on
# working days, which makes sense. The top right plot displays the relationship between non-subscriber rental count and
# temperature on working and non-working days seperately. On a non-working day we see about two thirds of a bell shape, while
# on a working day we see only about half of a bell shape that's also shorter, implying that the combination of working day
# and unfavarobale temprature specially reduces the number of bikes rented by non-subscribers. These two variables, i.e.,
# hour and temperature, exhibit cyclical patterns. We will shortly try to derive a few new features by transforming these
# predictors using sine and cosine functions. Lastly, since the size of observations is large, to confirm this cyclic pattern
# we look at the mean rental count against hour for instance.     

df <- group_by(bike.data, hr)
diagdf <- summarise(gdf, mean.casual=mean(casual))
ggplot(diagdf, aes(x=hr,y=mean.casual)) + geom_point() + labs(x="Hour") + labs(y="Mean Count")

#plot(density(bike.data$casual))
#rug(bike.data$casual)

# We begin by performing an ordinary least squares regression that includes all of the variables.   


lm.fit.00 <- lm(casual ~ ., data = bike.data)
summary(lm.fit.00)

# There are four significantly large coefficients, two positive and two negative, these are workingday, temp, atemp, and
# humidity. atemp has a particularly large SE of about 9.8. The coefficient for hour is about 0.43. temp, atemp, and humidity
# are normalized so their value is small. The RSE is at 33.45, and the Adjusted-r^2 is about 0.54. Three variables, season,
# month, and windspeed are not statistically significant. We check the diagnostic plots as well.   

par(mfrow=c(2,2))
plot(lm.fit.00)


# The residuals normality assumption is clearly violated as seen in the summary results and the diagnostic plots. There seems
# to be right-skewness. The funnel shape in the residuals vs fitted values plots indicate heteroscedasticity, suggesting the
# use of a quasi model. Further, there are a few points that have large cook's distances. They all have values for residual
# that is not concerning, but they do have large leveregase. We identify these points. 

#Get a list of the high leveraged points
#filter(bike.data0, hatvalues(lm.fit.00)>0.008)


# There are exactly 24 of them corresponding to 24 hours of a single day, August 17th, 2012. The total rental count for
# subscribers and non-subscribes on this day is actually lower than the previous day and apparently than the average of the
# month of August. The temperature is also similar to the previous day. However, the atemp variable, which is the "feels
# like" temperature has suddenly dropped to about a third of the previous day and is constant for all hours. We remove this
# single day from our data, instead of computing new values for them and check what takes place.

#filter(bike.data0, hatvalues(lm.fit.00)>0.008) %>% select(instant) 
new.data <- bike.data0[-c(14132:14155), -c(2,3,15)] # Remove the points. 
dim(new.data) # Check
#new.data[14132:14155,] # Check 

final.data00 <- read.csv("~/Desktop/bike.data02.csv")
final.data <- final.data00[,-c(2,3,15)]


lm.fit.01 <- lm(casual ~ ., data = final.data)
summary(lm.fit.01)
par(mfrow=c(2,2))
plot(lm.fit.01)


# The only important change is in the significane of variables since now the "temp" variable is statistically insignificant
# as it has a large p-value. "atemp" now has a much larger coefficient(84.7), but also a large standard error of about 12.5,
# but a very small p-value. Thus it plays an important role but the estimation for its coefficient is relatively instable. I
# was curious to see if this was the effect of removing the high leverage points, and thus undid that and placed new values
# for these 24 points based on the values of "temp" and the observed trend of "atemp" being generally less than "temp". The
# result is almost identical to when we remove these points. We proceed with using this final version of the data throught
# the rest of the paper. Lastly, plot of the residuals vs leverages was checked and it was no longer problematic. 

lm.01.preds <- predict(lm.fit.01, newdata = final.data, type = "response")
lm.01.train.err <- mean((final.data$casual - lm.01.preds)^2)
lm.01.train.err

#The training error on the final.data is 1116.5. 

#We now apply the sine and cosine transformations to the hour and temp variables since they exhibited cyclical patterns in
# the previous plots. Since the working day appeared to affect the amplitude of the shape by a factor, we tried to
# incorporate that into the model and it was unsuccesful as it did not make any tangible improvements. 

# We further added a few interaction terms that appeared to be statistically significant and slightly improve the adj-r^2 to
# 0.63. All of the derived features and interaction terms appear to be statistically significant with low SEs and very small
# p-values. 

# Lastly we transformed the response variable by take its square root. This appears to significantly improve the model. The
# RSE has dropped from around 30 to about 1.7, the adjusted-r^2 has raised to 0.78, and the residuals are much closer to
# being normally distributed now. Coefficients and their SEs also seem much more normalized and less wild. The training error
# has also dropped from 1116.5 to 897.  

lm.fit.11 <- lm(sqrt(casual) ~ . + hr:workingday:atemp + weathersit:registered + 
                  temp:weekday + sin(2*pi*hr/24) + cos(2*pi*hr/24) +
                  sin(2*pi*atemp/max(atemp)) + cos(2*pi*atemp/max(atemp)),
                data = final.data)


summary(lm.fit.11)


lm.11.train.preds <- predict(lm.fit.11, newdata = final.data, type = "response")
lm.11.train.err <- mean((final.data$casual - (lm.11.train.preds)^2)^2)
lm.11.train.err

par(mfrow=c(2,2))
plot(lm.fit.11)

#drop1(lm.fit.11, test = "F")

# The MSE on the original data is  is 681.5, which is improved compared to 1116.5 for the simple model, but still quite
# large! We display the diagnostic plots and it seems they are improved as well. The peculiar lines on the residuals plot are
# likely to be due to high frequency counts. 

# We also performed a variable selection by the drop1() function and noted that it suggests a 12-variable model (including
# the intercept) compared the the original 19-variable model. However, we tested the model and it was inferioir to the
# original model. So we keep all of the variables except for one of the interaction terms that was not significant, and
# proceed to fit this model to a training set and testing it on a validation set.  


# Create the test and training sets using 80% of the data for train and 20% for test.  
set.seed(1)
train <- sample(1:nrow(final.data), round(0.85*nrow(final.data),0)) 
train.set <- final.data[train,]
dim(train.set)
test.set <- final.data[-train,]
dim(test.set)


lm.fit.12 <- lm(sqrt(casual) ~ . + hr:workingday:atemp + weathersit:registered + 
                  temp:weekday + sin(2*pi*hr/24) + cos(2*pi*hr/24) +
                  sin(2*pi*atemp/max(atemp)) + cos(2*pi*atemp/max(atemp)),
                data = train.set)

# Compute the training MSE.
lm.12.train.preds <- predict(lm.fit.12, type = "response")
lm.12.train.err <- mean((train.set$casual - (lm.12.train.preds)^2)^2)
lm.12.train.err
# Compute the test MSE
lm.12.preds <- predict(lm.fit.12, newdata = test.set, type = "response")
lm.12.test.err <- mean((test.set$casual - (lm.12.preds)^2)^2)
lm.12.test.err


# The train MSE is 678.5 and the test MSE is 718.75, not a large departure from the training error.

# We look at the actual vs fitted values plot. Although the model seems to fit the data, it appears that it is not really
# predicting any large counts, which are available in the data. 

par(mfrow=c(1,1))
lp <- (lm.12.preds)^2
plot(test.set$casual~lp, ylab = "Test Response Count", xlab = "Predicted Values", 
     main = "Actual vs Predicted Values ")
abline(0,1,col="red")


# We now proceed to some count regression models. We begin by fitting a poisson regression model on the transfomed variable
# along with the interaction terms and derived feature, as this model was superior to the the simple poisson on the original
# variables (summary tables excluded). 

poisson.fit <- glm(sqrt(casual) ~ . + hr:workingday:atemp + weathersit:registered + 
                     temp:weekday + sin(2*pi*hr/24) + cos(2*pi*hr/24) +
                     sin(2*pi*atemp/max(atemp)) + cos(2*pi*atemp/max(atemp)), 
                   family = poisson, train.set) #response could not be transformed
summary(poisson.fit)
par(mfrow=c(2,2))
plot(poisson.fit)


# The residual deviance is significantly smaller than the null deviance, and smaller than the number of degrees of freedom.
# The coefficients are mild with small standard errors. The largest coefficient with a value of around 5 belongs to the
# "feels like" temperature. All of the variables except month are significant. We now look for outliers and then shortly move
# to use the quasi-Poisson model.

halfnorm(abs(residuals(poisson.fit)))


# There are two points on the top right corner that are furthur away from the rest, not not in an extreme manner, so we
# disregard them. We observe in the following plot that that general that the variance has a mild decreasing trend indicative
# of small amoun of underdispersion. This is confirmed by the estimation of dispersion parameter which is slightly less than
# 1, at 0.56.


par(mfrow=c(1,1))
plot(poisson.fit, which=3)

# Estimate the dispersion parameter
(dp <- sum(residuals(poisson.fit,type="pearson")^2)/poisson.fit$df.res)

# We now compute the test MSE.   

#Get the predicted values and transform back by squaring when getting the test MSE. 
poisson.preds <- predict(poisson.fit, newdata = test.set, type = "response")
poiss.test.err <- mean((test.set$casual-(poisson.preds)^2)^2)
poiss.test.err

# The test error of 450.9 is much smaller than the error from the linear regression model. We also look at the actual vs
# predicted values plot for the test set. It appears that the model does fit the data well. 

# Plot the actual test values vs the predicted values on the test set.
pp<-(poisson.preds)^2
plot(test.set$casual~pp, xlim=c(0,350))
abline(0,1, col = "red")


# In order to confirm our conclusion regarding the dispersion parameter, we fit a quasi-poisson model and check the results.

poiss.quasi.fit <- glm(sqrt(casual) ~ . + hr:workingday:atemp + weathersit:registered + 
                         temp:weekday + sin(2*pi*hr/24) + cos(2*pi*hr/24) +
                         sin(2*pi*atemp/max(atemp)) + cos(2*pi*atemp/max(atemp)), 
                       family = "quasipoisson", train.set)
#summary(poiss.quasi.fit)
quasi.poiss.preds <- predict(poiss.quasi.fit, newdata = test.set, type = "response")
quasi.test.err <- mean((test.set$casual-(quasi.poiss.preds)^2)^2)
quasi.test.err


# The results are identical so we disregard this model and proceed to fitting a negative binomial model. 

library("MASS")
neg.binom.fit <- glm(sqrt(casual) ~ . + hr:workingday:atemp + weathersit:registered + 
                       temp:weekday + sin(2*pi*hr/24) + cos(2*pi*hr/24) +
                       sin(2*pi*atemp/max(atemp)) + cos(2*pi*atemp/max(atemp)), 
                     negative.binomial(1),train.set) # Theta = 1 for geometric distribution. 
summary(neg.binom.fit)


# We observe that the dispersion parameter is very small, the coefficients are all small, with largest being about 1.02
# corresponding to the "feels like" temperature. The residual deviande is significantly lower than the previous two models
# and is about 3496. We now test the model.  


#drop1(neg.binom.fit, test = "F")
# The model suggested by drop1() does not improve the results. 

neg.binom.preds <- predict(neg.binom.fit, newdata = test.set, type = "response")
sp <- (neg.binom.preds)^2
neg.bin.test.err <- mean((test.set$casual-sp)^2)
neg.bin.test.err


# The test error is approximately 699, comparable to the linear regression model. We look at the actual vs predicted values
# plot and it looks quite similar to the one for the Poisson model. Again, it seems that the model does not predict any
# larger counts, which are available in the data.


# Plot the actual values against the predicted value.
par(mfrow=c(1,1))
plot(test.set$casual~sp, main = "Negative Binomial - Actual vs Predicted Values", xlab = "Predicted Values", 
     ylab = "Test Response Count")
abline(0,1, col = "red")


# In the first line of code below  we checked the number of zeroes in the dataset to determine whether or not we should fit a
# zero-inflated model. There are 1,581 zero counts in a total of 17,379, not very small, but not very large either, so we
# skip this model. We now try fitting a cross-validated Principal Component regression, followed by the two penalized
# regression methods, Ridge and Lasso regression, and end the analysis with a non-parametric regression model, KNN, just to
# compare the test results. 


# Check the number of zeroes in the daset 
sum(final.data$casual==0)

# Fit a PCR

library("pls")
set.seed(2)
pcr.fit <- pcr(casual ~., data=train.set ,scale=TRUE, validation ="CV")
#summary(pcr.fit)
validationplot(pcr.fit, val.type="MSEP", main = "PCR")
pcr.pred <- predict(pcr.fit,newdata = test.set, ncomp=11)
mean((pcr.pred-test.set$casual)^2)
plot(test.set$casual ~ pcr.pred, main = "Actual vs Predicted Values", xlab = "Predicted Values", 
     ylab = "Test Response Count")
abline(0,1, lwd = 1, col="red")



# Even with 11 components the model's performance is poor. We check the results for cross-validated Ridge and Lasso
# regressions with the original variables.  


# Fit a Ridge Regression

train.x <- as.matrix(train.set[,-11])
train.y <- as.matrix(train.set[,11])
test.x <- as.matrix(test.set[,-11])
test.y <- as.matrix(test.set[,11])

ridge.mod.cv <- cv.glmnet(x=train.x, y=train.y, alpha=0) # Perform cross-validation
best.lam <- ridge.mod.cv$lambda.min # Get the best lambda 

grid <- 10^seq(10,-2,length=100) # Create a grid 
ridge.mod <- glmnet(x=train.x, y=train.y, family = "poisson", alpha=0, lambda = grid) # Fit
ridge.pred <- predict(ridge.mod, s = best.lam, newx = test.x, type = "response") # Predicted values
ridge.test.err <- mean((test.set$casual-ridge.pred)^2) # Test error
ridge.test.err

# Test error is `r ridge.test.err`. 


# Fit Lasso

lasso.mod.cv <- cv.glmnet(x=train.x, y=train.y, alpha=1)
best.lam.lass <- lasso.mod.cv$lambda.min

grid1 = 10^seq(10,-2,length=100)
lasso.mod <- glmnet(x=train.x, y=train.y, family = "poisson", alpha=1, lambda = grid1)

lasso.pred <- predict(lasso.mod, s = best.lam.lass, newx = test.x, type = "response")
lasso.test.err <- mean((test.set$casual-lasso.pred)^2)
lasso.test.err


# The test error is very similar to that of the Ridge regression. Lastly, we try the non-parametric KNN regression on the
# test set and plot the actual vs predicted values for this model. 


# Fit a KNN with k=1 as the best k. 
knn.fit.preds <- knn(train.x, test.x, train.y , k=1)
knn.test.error <- mean((test.set$casual -as.numeric(knn.fit.preds))^2) 
knn.test.error

plot(test.set$casual ~ knn.fit.preds, main = "Actual vs Predicted Values", xlab = "Predicted Values", 
     ylab = "Test Response Count")
abline(0,1, lwd = 1, col="red")

```

# The test error for the KNN model is somewhere in between the previous models, closer to that of Ridge and Lasso. K=1 gave
# the best results for this model.


# We conclude our analysis by observing that all of the models that were fitted gave large test errors. We note that the
# simple least squares, Ridge and Lasso regressions gave similar errors. However, the derived features and added interactions
# could significantly improve the simple linear regression, bringing the test error to lower than that of the negative
# binomial model, and closest to the Poisson model test error, which was the lowest. 













