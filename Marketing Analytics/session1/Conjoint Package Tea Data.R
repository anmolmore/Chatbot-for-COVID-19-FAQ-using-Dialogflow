rm(list = ls())
try(require(conjoint))||install.packages("conjoint")
library(conjoint)

##########################################################3
#factorial design code
library(AlgDesign)
levels.design = c(3,3,3,2)
f.design <- gen.factorial(levels.design,factors='all')
optFederov(~.,f.design)
##########################################################

#alternate factorial design code used in the exercise
#expand.grid creates a Data Frame from All Combinations of Factor Variables
experiment<-expand.grid(
  price<-c("low","medium","high"),
  variety<-c("black","green","red"),
  kind<-c("bags","granulated","leafy"),
  aroma<-c("yes","no"))
experiment
##Fractional Design from Conjoint package
design<-caFactorialDesign(data=experiment)
colnames(design) <- c("price","variety","kind","aroma")
print(design)

###############################################################
##convert the design into coded format for regression. 
tprofile <- caEncodedDesign(design)
colnames(tprofile) <- c("price","variety","kind","aroma")
# convert trpofile in to dummy variable format for regression
print(tprofile)
tprof1=as.data.frame(lapply(tprofile[1:4],factor))
tprof_dm=model.matrix(~price+variety+kind+aroma,tprof1)
###############################################################

# analysis after collecting data. 
data(tea)
#tprefm contains the ratings of 13 profiles by 100 respondents
tprefm
#tt=t(tprefm)
#write.csv(tt,file="reponse_tea.csv")
#The Conjoint functions require the data in form of a list. The following code converts the response data into a list format.
tpref <- as.data.frame(as.vector(t(tprefm)))
colnames(tpref) <- c("Y")

# tlevn is a list of all the attribute levels
tlevn <- c("low","medium","high","black","green","red","bags","granulated","leafy","yes","no")

#tprof contains design read from tea data
print(tprof)
##Partworth utilities
part=caPartUtilities(y=tpref, x=tprof, z=tlevn)
part
#write.csv(part,file="part_tea.csv")
#Conjoint(y=tpref, x=tprof, z=tlevn)

caImportance(y=tpref, x=tprof)

##Segmentation. The parameter c has the no of clusters. 3 in this case.
seg=caSegmentation(y=tpref, x=tprof, c=3)
seg



