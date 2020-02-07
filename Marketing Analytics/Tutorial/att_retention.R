# Case : Predicting Customer Retention 

library(lattice)  # lattice plot
library(vcd)  # mosaic plots
library(gam)  # generalized additive models for probability smooth
library(rpart)  # tree-structured modeling
library(e1071)  # support vector machines
library(randomForest)  # random forests
library(rpart.plot)  # plot tree-structured model information
library(ROCR)  # ROC curve objects for binary classification 

# user-defined function for plotting ROC curve using ROC objects from ROCR
plot_roc <- function(train_roc, train_auc, test_roc, test_auc) {
  plot(train_roc, col = "blue", lty = "solid", main = "", lwd = 2,
       xlab = "False Positive Rate",
       ylab = "True Positive Rate")
  plot(test_roc, col = "red", lty = "dashed", lwd = 2, add = TRUE)
  abline(c(0,1))
  # Draw a legend.
  train.legend <- paste("Training AUC = ", round(train_auc, digits=3))
  test.legend <- paste("Test AUC =", round(test_auc, digits=3))
  legend("bottomright", legend = c(train.legend, test.legend),
         lty = c("solid", "dashed"), lwd = 2, col = c("blue", "red"))
}       


att <- read.csv("att.csv", stringsAsFactors = FALSE)
print(str(att))

# convert blank character fields to missing data codes
att[att == ""] <- NA

# convert character fields to factor fields 
att$pick <- factor(att$pick)
att$income <- factor(att$income)
att$moves <- factor(att$moves)
att$age <- factor(att$age)
att$education <- factor(att$education)
att$employment <- factor(att$employment)
att$nonpub <- factor(att$nonpub)
att$reachout <- factor(att$reachout)
att$card <- factor(att$card)

# check revised structure of att data frame
print(str(att))

# select usage and AT&T marketing plan factors
attwork <- subset(att, select = c("pick", "usage", "reachout", "card"))
attwork <- na.omit(attwork)

# listwise case deletion for usage and marketing factors
attwork <- na.omit(attwork)
print(summary(attwork))

# provide overview of data
print(summary(att))

# -----------------
# usage and pick
# -----------------
# examine relationship between age and response to promotion

lattice_plot_object <- histogram(~usage | pick, data = att,
                                 type = "density", xlab = "Telephone Usage (Minutes per Month)", 
                                 layout = c(1,2))
print(lattice_plot_object)  # switchers tend to have lower usage

att_gam_model <- gam(pick == "OCC"  ~ s(usage), family=binomial,data=att) 

# probability smooth for usage and switching

plot(att$usage, att$pick == "OCC", type="n", 
     ylim=c(-0.1,1.1), yaxt="n", 
     ylab="Estimated Probability of Switching", 
     xlab="Telephone Usage (Minutes per Month)") 
axis(2, at=c(0,.5,1)) 
points(jitter(att$usage), 
       att$pick=="OCC",pch="|") 
o <- order(att$usage) 
lines(att$usage[o],fitted(att_gam_model)[o]) 

# -----------------
# reachout and pick
# -----------------

# create a mosaic plot in using vcd package

mosaic( ~ pick + reachout, data = attwork,
        labeling_args = list(set_varnames = c(pick = "Service Provider Choice", 
                                              reachout = "AT&T Reach Out America Plan")),
        highlighting = "reachout",
        highlighting_fill = c("cornsilk","violet"),
        rot_labels = c(left = 0, top = 0),
        pos_labels = c("center","center"),
        offset_labels = c(0.0,0.6))


mosaic( ~ pick + card, data = attwork,
        labeling_args = list(set_varnames = c(pick = "Service Provider Choice", 
                                              card = "AT&T Credit Card")),
        highlighting = "card",
        highlighting_fill = c("cornsilk","violet"),
        rot_labels = c(left = 0, top = 0),
        pos_labels = c("center","center"),
        offset_labels = c(0.0,0.6))

# ----------------------------------
# fit logistic regression model 
# ----------------------------------
att_spec <- {pick ~ usage + reachout + card}
att_fit <- glm(att_spec, family=binomial, data=attwork)
print(summary(att_fit))

# compute predicted probability of switching service providers 
attwork$Predict_Prob_Switching <- predict.glm(att_fit, type = "response") 


plotting_object <- densityplot( ~ Predict_Prob_Switching | pick, 
                                data = attwork, 
                                layout = c(1,2), aspect=1, col = "darkblue", 
                                plot.points = "rug",
                                strip=function(...) strip.default(..., style=1),
                                xlab="Predicted Probability of Switching") 
print(plotting_object) 

# use a 0.5 cut-off in this problem
attwork$Predict_Pick <- 
  ifelse((attwork$Predict_Prob_Switching > 0.5), 2, 1)
attwork$Predict_Pick <- factor(attwork$Predict_Pick,
                               levels = c(1, 2), labels = c("AT&T", "OCC"))  
confusion_matrix <- table(attwork$Predict_Pick, attwork$pick)
cat("\nConfusion Matrix (rows=Predicted Service Provider,",
    "columns=Actual Service Provider\n")
print(confusion_matrix)
predictive_accuracy <- (confusion_matrix[1,1] + confusion_matrix[2,2])/(confusion_matrix[1,1] + confusion_matrix[2,2]+(confusion_matrix[1,2] + confusion_matrix[2,1]))

cat("\nPercent Accuracy: ", round(predictive_accuracy * 100, digits = 1))
# mosaic rendering of the classifier with 0.10 cutoff
with(attwork, print(table(Predict_Pick, pick, useNA = c("always"))))

mosaic( ~ Predict_Pick + pick, data = attwork,
        labeling_args = list(set_varnames = 
                               c(Predict_Pick = 
                                   "Predicted Service Provider (50 percent cut-off)",
                                 pick = "Actual Service Provider")),
        highlighting = c("Predict_Pick", "pick"),
        highlighting_fill = c("green","cornsilk","cornsilk","green"),
        rot_labels = c(left = 0, top = 0),
        pos_labels = c("center","center"),
        offset_labels = c(0.0,0.6))


# -----------------------------------------
# example of tree-structured classification 
# -----------------------------------------
att_tree_fit <- rpart(att_spec, data = attwork, 
                      control = rpart.control(cp = 0.0025))
# plot classification tree result from rpart

prp(att_tree_fit, main="",
    digits = 3,  # digits to display in terminal nodes
    nn = TRUE,  # display the node numbers
    branch = 0.5,  # change angle of branch lines
    branch.lwd = 2,  # width of branch lines
    faclen = 0,  # do not abbreviate factor levels
    trace = 1,  # print the automatically calculated cex
    shadow.col = 0,  # no shadows under the leaves
    branch.lty = 1,  # draw branches using dotted lines
    split.cex = 1.2,  # make the split text larger than the node text
    split.prefix = "is ",  # put "is" before split text
    split.suffix = "?",  # put "?" after split text
    split.box.col = "blue",  # lightgray split boxes (default is white)
    split.col = "white",  # color of text in split box 
    split.border.col = "blue",  # darkgray border on split boxes
    split.round = .25)  # round the split box corners a tad

# ---------------------------------------------
# example of random forest model for importance
# ---------------------------------------------
# fit random forest model to the training data
set.seed (9999)  # for reproducibility
attwork_rf_fit <- randomForest(att_spec, data = attwork, 
                               mtry=3, importance=TRUE, na.action=na.omit) 
# check importance of the individual explanatory variables 

varImpPlot(attwork_rf_fit, main = "", pch = 20, cex = 1.25)

# ------------------------------------------------------------
# training-and-test for evaluating alternative modeling methods 
# ------------------------------------------------------------
set.seed(2020)
partition <- sample(nrow(attwork)) # permuted list of row index numbers
attwork$group <- ifelse((partition < nrow(attwork)/(3/2)),1,2)
attwork$group <- factor(attwork$group, levels=c(1,2), 
                        labels=c("TRAIN","TEST"))
train <- subset(attwork, subset = (group == "TRAIN"), 
                select = c("pick", "usage", "reachout", "card"))
test <- subset(attwork, subset = (group == "TEST"), 
               select = c("pick", "usage", "reachout", "card"))
# ensure complete data in both partitions
train <- na.omit(train)
test <- na.omit(test)
# check partitions for no-overlap and correct pick frequencies
if(length(intersect(rownames(train), rownames(test))) != 0) 
  print("\nProblem with partition")  
print(table(attwork$pick))
print(table(test$pick)) 
print(table(train$pick))  

# --------------------------------------
# Logistic regression training-and-test
# --------------------------------------
# fit logistic regression model to the training set 
train_lr_fit <- glm(att_spec, family=binomial, data=train)
train$lr_predict_prob <- predict(train_lr_fit, type = "response")
train_lr_prediction <- prediction(train$lr_predict_prob, train$pick)
train_lr_auc <- as.numeric(performance(train_lr_prediction, "auc")@y.values)
# use model fit to training set to evaluate on test data
test$lr_predict_prob <- as.numeric(predict(train_lr_fit, newdata = test, 
                                           type = "response"))
test_lr_prediction <- prediction(test$lr_predict_prob, test$pick)
test_lr_auc <- as.numeric(performance(test_lr_prediction, "auc")@y.values)




# ----------------------------------------
# Random forest training-and-test
# ----------------------------------------
set.seed (9999)  # for reproducibility
train_rf_fit <- randomForest(att_spec, data = train, 
                             mtry=3, importance=FALSE, na.action=na.omit) 
train$rf_predict_prob <- as.numeric(predict(train_rf_fit, type = "prob")[,2])
train_rf_prediction <- prediction(train$rf_predict_prob, train$pick)
train_rf_auc <- as.numeric(performance(train_rf_prediction, "auc")@y.values)
# use model fit to training set to evaluate on test data
test$rf_predict_prob <- as.numeric(predict(train_rf_fit, newdata = test, 
                                           type = "prob")[,2])
test_rf_prediction <- prediction(test$rf_predict_prob, test$pick)
test_rf_auc <- as.numeric(performance(test_rf_prediction, "auc")@y.values)



# ----------------------------------------
# Naive Bayes training-and-test
# ----------------------------------------
set.seed (9999)  # for reproducibility
train_nb_fit <- naiveBayes(att_spec, data = train) 
train$nb_predict_prob <- as.numeric(predict(train_nb_fit, newdata = train,
                                            type = "raw")[,2])
train_nb_prediction <- prediction(train$nb_predict_prob, train$pick)
train_nb_auc <- as.numeric(performance(train_nb_prediction, "auc")@y.values)
# use model fit to training set to evaluate on test data
test$nb_predict_prob <- as.numeric(predict(train_nb_fit, newdata = test, 
                                           type = "raw")[,2])
test_nb_prediction <- prediction(test$nb_predict_prob, test$pick)
test_nb_auc <- as.numeric(performance(test_nb_prediction, "auc")@y.values)





