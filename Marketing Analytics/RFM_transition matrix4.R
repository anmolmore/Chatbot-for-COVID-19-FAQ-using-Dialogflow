
getwd()
rm(list=ls())

# Load text file into local variable called 'data'
data = read.delim(file = 'purchases.txt', header = FALSE, sep = '\t', dec = '.')

# Add headers and interpret the last column as a date, extract year of purchase
colnames(data) = c('customer_id', 'purchase_amount', 'date_of_purchase')
data$date_of_purchase = as.Date(data$date_of_purchase, "%Y-%m-%d")
data$year_of_purchase = as.numeric(format(data$date_of_purchase, "%Y"))
data$days_since       = as.numeric(difftime(time1 = "2016-01-01",
                                            time2 = data$date_of_purchase,
                                            units = "days"))

try(require("sqldf") || install.packages("sqldf"));library("sqldf")

# Segment customers in 2015
customers_2015 = sqldf("SELECT customer_id,
                               MIN(days_since) AS 'recency',
                               MAX(days_since) AS 'first_purchase',
                               COUNT(*) AS 'frequency',
                               AVG(purchase_amount) AS 'amount'
                        FROM data GROUP BY 1")
customers_2015$segment = "NA"
customers_2015$segment[which(customers_2015$recency > 365*2)] = "inactive"
customers_2015$segment[which(customers_2015$recency <= 365*2 & customers_2015$recency > 365)] = "cold"
customers_2015$segment[which(customers_2015$recency <= 365 & customers_2015$recency > 183)] = "warm"
customers_2015$segment[which(customers_2015$recency <= 183)] = "active"
customers_2015$segment[which(customers_2015$segment == "warm" & customers_2015$first_purchase <= 365)] = "new warm"
customers_2015$segment[which(customers_2015$segment == "warm" & customers_2015$amount < 60)] = "warm low value"
customers_2015$segment[which(customers_2015$segment == "warm" & customers_2015$amount >= 60)] = "warm high value"
customers_2015$segment[which(customers_2015$segment == "active" & customers_2015$first_purchase <= 183)] = "new active"
customers_2015$segment[which(customers_2015$segment == "active" & customers_2015$amount < 60)] = "active low value"
customers_2015$segment[which(customers_2015$segment == "active" & customers_2015$amount >= 60)] = "active high value"
customers_2015$segment = factor(x = customers_2015$segment, levels = c("inactive", "cold",
"warm high value", "warm low value", "active high value", "active low value", "new warm","new active"))
table(customers_2015$segment)
pie(table(customers_2015$segment), col = rainbow(24))

# Segment customers in 2014
customers_2014 = sqldf("SELECT customer_id,
                               MIN(days_since) - 365 AS 'recency',
                               MAX(days_since) - 365 AS 'first_purchase',
                               COUNT(*) AS 'frequency',
                               AVG(purchase_amount) AS 'amount'
                        FROM data
                        WHERE days_since > 365
                        GROUP BY 1")
customers_2014$segment = "NA"
customers_2014$segment[which(customers_2014$recency > 365*2)] = "inactive"
customers_2014$segment[which(customers_2014$recency <= 365*2 & customers_2014$recency > 365)] = "cold"
customers_2014$segment[which(customers_2014$recency <= 365 & customers_2014$recency > 183)] = "warm"
customers_2014$segment[which(customers_2014$recency <= 183)] = "active"
customers_2014$segment[which(customers_2014$segment == "warm" & customers_2014$first_purchase <= 365)] = "new warm"
customers_2014$segment[which(customers_2014$segment == "warm" & customers_2014$amount < 60)] = "warm low value"
customers_2014$segment[which(customers_2014$segment == "warm" & customers_2014$amount >= 60)] = "warm high value"
customers_2014$segment[which(customers_2014$segment == "active" & customers_2014$first_purchase <= 183)] = "new active"
customers_2014$segment[which(customers_2014$segment == "active" & customers_2014$amount < 60)] = "active low value"
customers_2014$segment[which(customers_2014$segment == "active" & customers_2014$amount >= 60)] = "active high value"
customers_2014$segment = factor(x = customers_2014$segment, levels = c("inactive", "cold",
"warm high value", "warm low value","active high value", "active low value","new warm","new active"))
table(customers_2014$segment)
pie(table(customers_2014$segment), col = rainbow(24))
# Compute transition matrix
new_data = merge(x = customers_2014, y = customers_2015, by = "customer_id", all.x = TRUE)
#head(new_data)
transition = table(new_data$segment.x, new_data$segment.y)
print(transition)

# Divide each row by its sum
transition = transition / rowSums(transition)
print(transition)


# --- USE TRANSITION MATRIX TO MAKE PREDICTIONS ------------


# Initialize a matrix with the number of customers in each segment today and after 10 periods
segments = matrix(nrow = 8, ncol = 11)
segments[, 1] = table(customers_2015$segment)
colnames(segments) = 2015:2025
row.names(segments) = levels(customers_2015$segment)
print(segments)

# Compute for each an every period
for (i in 2:11) {
   segments[, i] = segments[, i-1] %*% transition
}
# Display how segments will evolve over time
print(round(segments))
# Plot inactive, active high value customers over time
barplot(segments[1, ])
barplot(segments[2, ])


# --- COMPUTE THE (DISCOUNTED) CLV OF A DATABASE -----------
# Yearly revenue per segment
# Compute how much revenue is generated by segments
# Notice that people with no revenue in 2015 do NOT appear
revenue_2015 = sqldf("SELECT customer_id, SUM(purchase_amount) AS 'revenue_2015'
                     FROM data
                     WHERE year_of_purchase = 2015
                     GROUP BY 1")
summary(revenue_2015)
# Merge 2015 customers and 2015 revenue 
customers_2015 = merge(customers_2015, revenue_2015, all.x = TRUE)
customers_2015$revenue_2015[is.na(customers_2015$revenue_2015)] = 0
# Show average revenue per customer and per segment
r=aggregate(x = customers_2015$revenue_2015, by = list(customers_2015$segment), mean)
# Re-order and display results
r$Group.1 = factor(x = r$Group.1, levels = c("inactive", "cold","warm high value", "warm low value", "new warm","active high value", "active low value","new active"))
print(r);
yearly_revenue=r$x

# Compute revenue per segment
revenue_per_segment = yearly_revenue * segments
print(round(revenue_per_segment))

# Compute yearly revenue
yearly_revenue = colSums(revenue_per_segment)
print(round(yearly_revenue))
barplot(yearly_revenue)

# Compute cumulated revenue
cumulated_revenue = cumsum(yearly_revenue)
print(round(cumulated_revenue))
barplot(cumulated_revenue)

# Create a discount factor
discount_rate = 0.10
discount = 1 / ((1 + discount_rate) ^ ((1:11) - 1))
print(discount)

# Compute discounted yearly revenue
disc_yearly_revenue = yearly_revenue * discount
print(round(disc_yearly_revenue))
barplot(disc_yearly_revenue)
lines(yearly_revenue)

# Compute discounted cumulated revenue
disc_cumulated_revenue = cumsum(disc_yearly_revenue)
print(round(disc_cumulated_revenue))
barplot(disc_cumulated_revenue)

# What is the database worth?
print(disc_cumulated_revenue[11] - yearly_revenue[1])

