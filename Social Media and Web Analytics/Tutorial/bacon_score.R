#bacon score
library(igraph)
library(readr)
actors <- read_csv("actors.csv")
movies <- read_csv("movies.csv")


actors
movies
actorNetwork <- graph_from_data_frame(d=movies, vertices=actors, directed=F)
plot(actorNetwork)

E(actorNetwork)$color <- ifelse(E(actorNetwork)$Movie == "Forest Gump", "green", 
                                ifelse(E(actorNetwork)$Movie == "Apollo 13", "black",
                                       "orange"))

# Re-Plot the network
plot(actorNetwork)

V(actorNetwork)$color <- ifelse(V(actorNetwork)$BestActorActress == "Winner", "gold",
                                ifelse(V(actorNetwork)$BestActorActress == "Nominated","grey",
                                       "lightblue"))

#Re-Plot the Network
plot(actorNetwork)

plot(actorNetwork, vertex.frame.color="white")

legend("bottomright", c("Winner","Nominee", "Not Nominated"), pch=21,
       col="#777777", pt.bg=c("gold","grey","lightblue"), pt.cex=2, cex=.8)


legend("topleft", c("Forest Gump","Apollo 13", "The Rock"), 
       col=c("green","black","orange"), lty=1, cex=.8)

#Degree centrality is simplest of the methods, it measures the number of 
#connections between a node and all other nodes. 
degree(actorNetwork, mode="all") 

#Closeness centrality is an evaluation of the proximity of a node to all other nodes 
#in a network, not only the nodes to which it is directly connected. 
#The closeness centrality of a node is defined by the inverse of the average 
#length of the shortest paths to or from all the other nodes in the graph.

closeness(actorNetwork, mode="all", weights=NA, normalized=T)


betweenness(actorNetwork, directed=F, weights=NA, normalized = T)

# bacon score

distances(actorNetwork, v=V(actorNetwork)["Kevin Bacon"], to=V(actorNetwork), weights=NA)



