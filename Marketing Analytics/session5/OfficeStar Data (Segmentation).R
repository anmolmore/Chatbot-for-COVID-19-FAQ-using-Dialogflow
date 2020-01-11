getwd()
rm(list=ls())
dev.off()
try(require(readxl) || install.packages("readxl",dependencies = TRUE))
try(require(MASS) || install.packages("MASS",dependencies = TRUE))

library(readxl)

Segmentation.Data <- read_excel("OfficeStar Data (Segmentation).xls", sheet = "Segmentation Data", skip = 3, col_names = TRUE)

OfficeStarCluster <- kmeans(Segmentation.Data[,2:7],3)

OfficeStarCluster

OfficeStarCluster$cluster


Discrimination.Data <- read_excel("OfficeStar Data (Segmentation).xls", sheet = "Discrimination Data", skip = 3, col_names = TRUE)
Discrimination.Data$Professional <- factor(Discrimination.Data$Professional)
Discrimination.Data$officegroup <- OfficeStarCluster$cluster
View(Discrimination.Data)
officestar.lda <- lda(officegroup ~ ., data=Discrimination.Data[,2:5])
officestar.lda

officestar.lda.values <- predict(officestar.lda)
#officestar.lda.values
Discrimination.Data$predictedgroup <- officestar.lda.values$class


#ldahist(data = officestar.lda.values$x[,1], g=Discrimination.Data$officegroup)
#plot(officestar.lda.values$x[,1],officestar.lda.values$x[,2])
#text(officestar.lda.values$x[,1],officestar.lda.values$x[,2],Discrimination.Data$officegroup,cex=0.7,pos=4,col="red")


ConfusionMatrix <- table(Discrimination.Data$officegroup,Discrimination.Data$predictedgroup)

ConfusionMatrix

ConfusionMatrix.in.Percentage <- round(prop.table(ConfusionMatrix,2) * 100,2)

ConfusionMatrix.in.Percentage


Correct.Predictions <- ConfusionMatrix[1,1] + ConfusionMatrix[2,2] + ConfusionMatrix[3,3] 

hitrate <- round(Correct.Predictions / length(Discrimination.Data$officegroup) * 100, 2)

hitrate



Classification.Data <- read_excel("OfficeStar Data (Segmentation).xls", sheet = "Classification Data", skip = 6, col_names = TRUE)
Classification.Data$Professional <- factor(Classification.Data$Professional)

Classification.Data.lda.values <- predict(officestar.lda, newdata = Classification.Data[,2:4])

Classification.Data.lda.values$class



 
