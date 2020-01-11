library(tidyverse)
library(rtweet)
rstats <- search_tweets("#rstats", n = 50)
ben <- search_tweets("BenInquiring", n = 50)
ben
ben_profile <- search_users("BenInquiring")
ben_profile$name
ben_profile$description
ben_profile$location
rate_limit()
my_followers <- get_followers("BenInquiring")
glimpse(my_followers)



friends <- read_csv("twitter_friends.csv")
filter(friends, friend %in% user)
net <- friends %>% 
  group_by(friend) %>% 
  mutate(count = n()) %>% 
  ungroup() %>% 
  filter(count > 1)
glimpse(net)

library(tidygraph)

g <- net %>% 
  select(user, friend) %>%  # drop the count column
  as_tbl_graph()
g

library(ggraph)
ggraph(g) +
  geom_edge_link() +
  geom_node_point(size = 3, colour = 'steelblue') +
  theme_graph()

g2 <- net %>% 
  select(user, friend) %>%  # drop the count column
  as_tbl_graph(directed = F) %>%  # make undirected
  activate(nodes) %>% 
  mutate(centrality = centrality_degree())
g2

ggraph(g2) +
  geom_edge_link() +
  geom_node_point(aes(size = centrality, colour = centrality)) +
  theme_graph()
