getwd()
rm(list=ls())
#try(require(rmarkdown))||install.packages("rmarkdown");library(rmarkdown)
# Load text file into local variable called 'data'
data = read.delim(file = 'purchases.txt', header = FALSE, sep = '\t', dec = '.')

# Display what has been loaded
head(data)

# Add headers and interpret the last column as a date, extract year of purchase
colnames(data) = c('customer_id', 'purchase_amount', 'date_of_purchase')
data$date_of_purchase = as.Date(data$date_of_purchase, "%Y-%m-%d")
data$year_of_purchase = as.numeric(format(data$date_of_purchase, "%Y"))

# Display the data set after transformation
head(data)
summary(data)

# Explore the data using simple SQL statements
try(require("sqldf") || install.packages("sqldf"));library("sqldf")

# SELECT column_name(s)
# FROM table_name
# WHERE condition
# GROUP BY column_name(s)
# ORDER BY column_name(s);

# Summary of mumber of purchases per year, average purchase amount per year, total purchase amounts per year
x = sqldf("SELECT year_of_purchase,
                  COUNT(year_of_purchase) AS 'purchases',
                  AVG(purchase_amount) AS 'avg_amount',
                  SUM(purchase_amount) AS 'sum_amount'
           FROM data GROUP BY 1 ORDER BY 1")
print(x)

barplot(x$purchases, names.arg = x$year_of_purchase, main = "number of purchases per year")
barplot(x$avg_amount, names.arg = x$year_of_purchase, main="avg amount per year")
barplot(x$sum_amount, names.arg = x$year_of_purchase, main="total amount per year")

# Counting days
data$days_since       = as.numeric(difftime(time1 = "2016-01-01",
                                            time2 = data$date_of_purchase,
                                            units = "days"))

# RFM Calculations
customers = sqldf("SELECT customer_id,
                          MIN(days_since) AS 'recency',
                          COUNT(*) AS 'frequency',
                          AVG(purchase_amount) AS 'monetary'
                   FROM data GROUP BY 1")
summary(customers)

hist(customers$recency)
hist(customers$frequency)
hist(customers$monetary, breaks=1000, xlim=c(0,300))
# Take the log-transform of the monetary, and plot
customers$lnmonetary=log(customers$monetary)
hist(customers$lnmonetary)

cor(customers[,2:5])

# Remove customer id as a variable, store it as row names
new_data = customers
head(new_data)
row.names(new_data) = new_data$customer_id
new_data$customer_id = NULL
new_data$monetary =NULL
head(new_data)

# Standardize variables
new_data = scale(new_data)
head(new_data)

# Determine number of clusters
wss <- (nrow(new_data)-1)*sum(apply(new_data,2,var))
for (i in 2:15) wss[i] <- sum(kmeans(new_data, 
                                     centers=i)$withinss)
plot(1:15, wss, type="b", xlab="Number of Clusters",
     ylab="Within groups sum of squares")
# K-Means Cluster Analysis
fit <- kmeans(new_data, 7) # 7 cluster solution
# append cluster assignment
kmean_data <- data.frame(customers, fit$cluster)
# Show profile of each segment
#aggregate(new_data,by=list(fit$cluster),FUN=mean)
pie(table(kmean_data$fit.cluster), col = rainbow(24))
aggregate(kmean_data[, 2:4], by = list(fit$cluster), mean)


# Perform hierarchical clustering on distance metrics
# Compute distance metrics on standardized data
d = dist(new_data)
c = hclust(d, method="ward.D2")
# Plot de dendogram
plot(c)
# Cut at 8 segments
members = cutree(c, k = 7)
# draw dendogram with red borders around the 7 clusters 
rect.hclust(c, k=7, border="red")
# Show profile of each segment
#aggregate(new_data, by = list(members), mean)
hclust_data <- data.frame(customers, members)
pie(table(hclust_data$members), col = rainbow(24))
aggregate(hclust_data[, 2:4], by = list(members), mean)

