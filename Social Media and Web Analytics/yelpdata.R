#install necessary packages if you don't already have those
install.packages("tidyr")
install.packages("dplyr")
install.packages("stringr")
install.packages("jsonlite")
install.packages("tidytext")
install.packages("readr")
install.packages("ggplot2")
install.packages("textdata")

#load libraries 
library(readr)
library(stringr)
library(jsonlite)
library(dplyr)

library(readxl)
yelp_data <- read_excel("S1 Yelp_data.xlsm")
View(yelp_data)

# sentiment analysis
# a) Cleaning up reviews - this basically involves the removal of stopwords (e.g., “and”, “a”, “the”, “his”) and punctuation marks.
# b) Separating out words, so that each row of data now has the star rating and one word.
# c) Classifying the ‘sentiment’ of the words, i.e., are the words ‘positive’ or ‘negative’. For this we’ll use a lexicon. 
# d) Produce a final data frame that has one row per review, containing the star rating as well as a ‘sentiment score’ associate with the review.

#summon tidytext library
library(textdata)
library(tidytext)

review_words <- yelp_data %>%
select(review_id, business_id, stars, text) %>%
unnest_tokens(word, text) %>%
filter(!word %in% stop_words$word,str_detect(word, "^[a-z']+$"))
#View review_words
View(review_words)

#apply AFINN
newsentiment <- get_sentiments("afinn") %>%
select(word, afinn_score = value)

#see assigned scores
View(newsentiment)

#combine the scores and assign to each review
reviews_sentiment <- review_words %>%
  inner_join(newsentiment, by = "word") %>%
  group_by(review_id, stars) %>%
  summarize(sentiment = mean(afinn_score))

View(reviews_sentiment)

#This is a scatterplot/boxplot of sentiment scores vs. 5 star rating 
library(ggplot2)
theme_set(theme_bw())
ggplot(reviews_sentiment, aes(stars, sentiment, group = stars)) +
  geom_boxplot() +
  ylab("Average sentiment score")

#In which reviews, how often in those reviews words appear and review rating 
review_words_counted <- review_words %>%
count(review_id, business_id, stars, word) %>%
  ungroup()

View(review_words_counted)

review_words_counted$stars<-as.numeric(review_words_counted$stars)

#Look at the word frequencies
word_summaries <- review_words_counted %>%
  group_by(word) %>%
  summarize(businesses = n_distinct(business_id),
            reviews = n(),
            uses = sum(n),
            average_stars = mean(stars)) %>%
  ungroup()

View(word_summaries)

#choose words for analysis that appear in at least 200 reviews and for at least 10 businesses
word_summaries_filtered <- word_summaries %>%
  filter(reviews >= 200, businesses >= 10)

View(word_summaries_filtered)

#check the frequent positive words
word_summaries_filtered %>%
  arrange(desc(average_stars))

#check the frequent negative words
word_summaries_filtered %>%
  arrange(average_stars)

#plot results
ggplot(word_summaries_filtered, aes(reviews, average_stars)) +
  geom_point() +
  geom_text(aes(label = word), check_overlap = TRUE, vjust = 1, hjust = 1) +
  scale_x_log10() +
  geom_hline(yintercept = word_summaries_filtered$average_stars, color = "red", lty = 2) +
  xlab("# of reviews") +
  ylab("Average Stars")


#looking at relation between lexicon and ratings
words_afinn <- word_summaries_filtered %>%
  inner_join(newsentiment)

View(words_afinn)

#plot of ratings versus lexicon scores with colour coding 
ggplot(words_afinn, aes(reviews, average_stars, color = afinn_score)) +
  geom_point() +
  geom_text(aes(label = word), check_overlap = TRUE, vjust = 1, hjust = 1) +
  scale_x_log10() +
  geom_hline(yintercept = words_afinn$average_stars, color = "red", lty = 2) +
  scale_colour_gradient2("AFINN", low = "red", mid = "white", high = "blue", limits = c(-5,5)) +
  xlab("# of reviews") +
  ylab("Average Stars")

#box plot of ratings vs. lexicon scores
ggplot(words_afinn, aes(afinn_score, average_stars, group = afinn_score)) +
  geom_boxplot() +
  xlab("AFINN score of word") +
  ylab("Average stars of reviews with this word")


