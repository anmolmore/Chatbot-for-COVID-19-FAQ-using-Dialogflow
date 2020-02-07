# Case : Bank Targeting 

library(lattice)  
library(vcd)  
library(ROCR)  

bank <- read.csv("bank.csv", sep = ";", stringsAsFactors = FALSE)

# examine the structure of the bank data frame
print(str(bank))

# look at the first few rows of the bank data frame
print(head(bank))

# look at the list of column names for the variables
print(names(bank))

# look at class and attributes of one of the variables
print(class(bank$age))
print(attributes(bank$age))  # NULL means no special attributes defined
# plot a histogram for this variable
with(bank, hist(age))

# examine the frequency tables for categorical/factor variables  
# showing the number of observations with missing data (if any)

print(table(bank$job , useNA = c("always")))
print(table(bank$marital , useNA = c("always")))
print(table(bank$education , useNA = c("always")))
print(table(bank$default , useNA = c("always")))
print(table(bank$housing , useNA = c("always")))
print(table(bank$loan , useNA = c("always")))

# Type of job (admin., unknown, unemployed, management,
# housemaid, entrepreneur, student, blue-collar, self-employed,
# retired, technician, services)
# put job into three major categories defining the factor variable jobtype
# the "unknown" category is how missing data were coded for job... 
# include these in "Other/Unknown" category/level
white_collar_list <- c("admin.","entrepreneur","management","self-employed")  
blue_collar_list <- c("blue-collar","services","technician")
bank$jobtype <- rep(3, length = nrow(bank))
bank$jobtype <- ifelse((bank$job %in% white_collar_list), 1, bank$jobtype) 
bank$jobtype <- ifelse((bank$job %in% blue_collar_list), 2, bank$jobtype) 
bank$jobtype <- factor(bank$jobtype, levels = c(1, 2, 3), 
    labels = c("White Collar", "Blue Collar", "Other/Unknown"))
with(bank, table(job, jobtype, useNA = c("always")))  # check definition    

# define factor variables with labels for plotting
bank$marital <- factor(bank$marital, 
    labels = c("Divorced", "Married", "Single"))
bank$education <- factor(bank$education, 
    labels = c("Primary", "Secondary", "Tertiary", "Unknown"))
bank$default <- factor(bank$default, labels = c("No", "Yes"))
bank$housing <- factor(bank$housing, labels = c("No", "Yes"))
bank$loan <- factor(bank$loan, labels = c("No", "Yes"))
bank$response <- factor(bank$response, labels = c("No", "Yes"))
    
# select subset of cases never perviously contacted by sales
# keeping variables needed for modeling
bankwork <- subset(bank, subset = (previous == 0),
    select = c("response", "age", "jobtype", "marital", "education", 
               "default", "balance", "housing", "loan"))

# examine the structure of the bank data frame
print(str(bankwork))

# look at the first few rows of the bank data frame
print(head(bankwork))

# compute summary statistics for initial variables in the bank data frame
print(summary(bankwork))

# -----------------
# age  Age in years
# -----------------
# examine relationship between age and response to promotion

lattice_plot_object <- histogram(~age | response, data = bankwork,
    type = "density", xlab = "Age of Bank Client", layout = c(1,2))
print(lattice_plot_object)  # responders tend to be older

# -----------------------------------------------------------
# education
# Level of education (unknown, secondary, primary, tertiary)
# -----------------------------------------------------------
# examine the frequency table for education
# the "unknown" category is how missing data were coded 
with(bankwork, print(table(education, response, useNA = c("always"))))

# create a mosaic plot in using vcd package

mosaic( ~ response + education, data = bankwork,
  labeling_args = list(set_varnames = c(response = "Response to Offer", 
  education = "Education Level")),
  highlighting = "education",
  highlighting_fill = c("cornsilk","violet","purple","white",
      "cornsilk","violet","purple","white"),
  rot_labels = c(left = 0, top = 0),
  pos_labels = c("center","center"),
  offset_labels = c(0.0,0.6))

# ---------------------------------------------------------------
# job status using jobtype
# White Collar: admin., entrepreneur, management, self-employed  
# Blue Collar: blue-collar, services, technician
# Other/Unknown
# ---------------------------------------------------------------
# review the frequency table for job types
with(bankwork, print(table(jobtype, response, useNA = c("always"))))

mosaic( ~ response + jobtype, data = bankwork,
  labeling_args = list(set_varnames = c(response = "Response to Offer", 
  jobtype = "Type of Job")),
  highlighting = "jobtype",
  highlighting_fill = c("cornsilk","violet","purple",
      "cornsilk","violet","purple"),
  rot_labels = c(left = 0, top = 0),
  pos_labels = c("center","center"),
  offset_labels = c(0.0,0.6))

# ----------------------------------------------
# marital status
# Marital status (married, divorced, single)
# [Note: ``divorced'' means divorced or widowed]
# ----------------------------------------------
# examine the frequency table for marital status
# anyone not single or married was classified as "divorced"
with(bankwork, print(table(marital, response, useNA = c("always"))))

mosaic( ~ response + marital, data = bankwork,
  labeling_args = list(set_varnames = c(response = "Response to Offer", 
  marital = "Marital Status")),
  highlighting = "marital",
  highlighting_fill = c("cornsilk","violet","purple",
      "cornsilk","violet","purple"),
  rot_labels = c(left = 0, top = 0),
  pos_labels = c("center","center"),
  offset_labels = c(0.0,0.6))

# -----------------------------------------
# default  Has credit in default? (yes, no)
# -----------------------------------------
with(bankwork, print(table(default, response, useNA = c("always"))))

mosaic( ~ response + default, data = bankwork,
  labeling_args = list(set_varnames = c(response = "Response to Offer", 
  default = "Has credit in default?")),
  highlighting = "default",
  highlighting_fill = c("cornsilk","violet"),
  rot_labels = c(left = 0, top = 0),
  pos_labels = c("center","center"),
  offset_labels = c(0.0,0.6))

# ------------------------------------------
# balance  Average yearly balance (in Euros)
# ------------------------------------------
# examine relationship between age and response to promotion

lattice_plot_object <- histogram(~balance | response, data = bankwork,
    type = "density", 
    xlab = "Bank Client Average Yearly Balance (in dollars)", 
    layout = c(1,2))
print(lattice_plot_object)  # responders tend to be older

# ------------------------------------
# housing  Has housing loan? (yes, no)
# ------------------------------------
with(bankwork, print(table(housing, response, useNA = c("always"))))

mosaic( ~ response + housing, data = bankwork,
  labeling_args = list(set_varnames = c(response = "Response to Offer", 
  housing = "Has housing loan?")),
  highlighting = "housing",
  highlighting_fill = c("cornsilk","violet"),
  rot_labels = c(left = 0, top = 0),
  pos_labels = c("center","center"),
  offset_labels = c(0.0,0.6))

# ----------------------------------
# loan  Has personal loan? (yes, no)
# ----------------------------------
with(bankwork, print(table(loan, response, useNA = c("always"))))

mosaic( ~ response + loan, data = bankwork,
  labeling_args = list(set_varnames = c(response = "Response to Offer", 
  loan = "Has personal loan?")),
  highlighting = "loan",
  highlighting_fill = c("cornsilk","violet"),
  rot_labels = c(left = 0, top = 0),
  pos_labels = c("center","center"),
  offset_labels = c(0.0,0.6))

# ----------------------------------
# specify predictive model
# ----------------------------------
bank_spec <- {response ~ age + jobtype + education + marital +
    default + balance + housing + loan}

# ----------------------------------
# fit logistic regression model 
# ----------------------------------
bank_fit <- glm(bank_spec, family=binomial, data=bankwork)
print(summary(bank_fit))

# compute predicted probability of responding to the offer 
bankwork$Predict_Prob_Response <- predict.glm(bank_fit, type = "response") 


plotting_object <- densityplot( ~ Predict_Prob_Response | response, 
               data = bankwork, 
               layout = c(1,2), aspect=1, col = "darkblue", 
               plot.points = "rug",
               strip=function(...) strip.default(..., style=1),
               xlab="Predicted Probability of Responding to Offer") 
print(plotting_object) 

# predicted response to offer using using 0.5 cut-off
# notice that this does not work due to low base rate
# we get more than 90 percent correct with no model 
# (predicting all NO responses)
# the 0.50 cutoff yields all NO predictions 
bankwork$Predict_Response <- 
    ifelse((bankwork$Predict_Prob_Response > 0.5), 2, 1)
bankwork$Predict_Response <- factor(bankwork$Predict_Response,
    levels = c(1, 2), labels = c("NO", "YES"))  
confusion_matrix <- table(bankwork$Predict_Response, bankwork$response)
cat("\nConfusion Matrix (rows=Predicted Response, columns=Actual Choice\n")
print(confusion_matrix)
predictive_accuracy <- (confusion_matrix[1,1] + confusion_matrix[2,2])/(confusion_matrix[1,1] + confusion_matrix[2,2]+(confusion_matrix[1,2] + confusion_matrix[2,1]))
  cat("\nPercent Accuracy: ", round(predictive_accuracy * 100, digits = 1))

# this problem requires either a much lower cut-off
# or other criteria for evaluation... let's try 0.10 (10 percent cut-off)
bankwork$Predict_Response <- 
    ifelse((bankwork$Predict_Prob_Response > 0.1), 2, 1)
bankwork$Predict_Response <- factor(bankwork$Predict_Response,
    levels = c(1, 2), labels = c("NO", "YES"))  
confusion_matrix <- table(bankwork$Predict_Response, bankwork$response)
cat("\nConfusion Matrix (rows=Predicted Response, columns=Actual Choice\n")
print(confusion_matrix)
predictive_accuracy <- (confusion_matrix[1,1] + confusion_matrix[2,2])/(confusion_matrix[1,1] + confusion_matrix[2,2]+(confusion_matrix[1,2] + confusion_matrix[2,1]))
cat("\nPercent Accuracy: ", round(predictive_accuracy * 100, digits = 1))
# mosaic rendering of the classifier with 0.10 cutoff
with(bankwork, print(table(Predict_Response, response, useNA = c("always"))))

mosaic( ~ Predict_Response + response, data = bankwork,
  labeling_args = list(set_varnames = 
  c(Predict_Response = 
      "Predicted Response to Offer (10 percent cut-off)",
       response = "Actual Response to Offer")),
  highlighting = c("Predict_Response", "response"),
  highlighting_fill = c("green","cornsilk","cornsilk","green"),
  rot_labels = c(left = 0, top = 0),
  pos_labels = c("center","center"),
  offset_labels = c(0.0,0.6))




    


  