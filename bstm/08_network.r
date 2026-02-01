# ============================================================================
# STBM ANALYSIS - STEP 08: NETWORK VISUALIZATION
# ============================================================================
# Purpose: Create publication-ready network visualizations
# Prerequisites: Clean dataset and thematic analysis
# Note: For advanced visualization, also use VOSviewer (external software)
# ============================================================================

# Load required libraries
library(bibliometrix)
library(igraph)
library(dplyr)
library(ggplot2)
library(ggraph)

cat("=== NETWORK VISUALIZATION ===\n\n")

# ============================================================================
# LOAD DATASET
# ============================================================================

cat("1. Loading dataset...\n")
load("02_Processed_Data/final_dataset_clean.RData")
M <- final_data_clean
cat("   ✓ Loaded:", nrow(M), "documents\n\n")

# ============================================================================
# CO-AUTHORSHIP NETWORK
# ============================================================================

cat("2. Creating co-authorship network...\n")

# Create author collaboration network
author_net <- biblioNetwork(M, 
                           analysis = "collaboration", 
                           network = "authors",
                           sep = ";")

# Convert to igraph object for visualization
author_graph <- graph_from_adjacency_matrix(author_net, 
                                            mode = "undirected",
                                            weighted = TRUE)

# Calculate network metrics
author_degree <- degree(author_graph)
author_betweenness <- betweenness(author_graph)
author_closeness <- closeness(author_graph)

# Get top authors by degree
top_authors_net <- data.frame(
  Author = names(author_degree),
  Degree = author_degree,
  Betweenness = author_betweenness,
  Closeness = author_closeness
) %>%
  arrange(desc(Degree)) %>%
  head(30)

write.csv(top_authors_net, "04_Results/Networks/author_network_metrics.csv", row.names = FALSE)
cat("   ✓ Author network created\n")
cat("   Network size:", vcount(author_graph), "authors,", ecount(author_graph), "collaborations\n")

# Filter to top 30 authors for visualization
top_author_names <- top_authors_net$Author
author_subgraph <- induced_subgraph(author_graph, V(author_graph)[name %in% top_author_names])

# Detect communities
communities <- cluster_louvain(author_subgraph)
V(author_subgraph)$community <- membership(communities)

# Visualize
png("04_Results/Figures/coauthorship_network.png", width = 3600, height = 3600, res = 300)

set.seed(123)
plot(author_subgraph,
     vertex.size = degree(author_subgraph) * 2,
     vertex.label.cex = 0.7,
     vertex.color = membership(communities),
     vertex.label.color = "black",
     vertex.frame.color = "white",
     edge.width = E(author_subgraph)$weight / 2,
     edge.color = "gray70",
     layout = layout_with_fr(author_subgraph),
     main = "Co-Authorship Network (Top 30 Authors)")

dev.off()
cat("   ✓ Co-authorship network plotted\n\n")

# ============================================================================
# KEYWORD CO-OCCURRENCE NETWORK
# ============================================================================

cat("3. Creating keyword co-occurrence network...\n")

# Create keyword network
keyword_net <- biblioNetwork(M,
                            analysis = "co-occurrences",
                            network = "keywords",
                            sep = ";")

# Convert to igraph
keyword_graph <- graph_from_adjacency_matrix(keyword_net,
                                            mode = "undirected",
                                            weighted = TRUE)

# Calculate metrics
keyword_degree <- degree(keyword_graph)
keyword_betweenness <- betweenness(keyword_graph)
keyword_eigenvector <- eigen_centrality(keyword_graph)$vector

# Get top keywords
top_keywords_net <- data.frame(
  Keyword = names(keyword_degree),
  Degree = keyword_degree,
  Betweenness = keyword_betweenness,
  Eigenvector_Centrality = keyword_eigenvector
) %>%
  arrange(desc(Degree)) %>%
  head(50)

write.csv(top_keywords_net, "04_Results/Networks/keyword_network_metrics.csv", row.names = FALSE)
cat("   ✓ Keyword network created\n")
cat("   Network size:", vcount(keyword_graph), "keywords,", ecount(keyword_graph), "connections\n")

# Filter to top 30 keywords with strong connections
top_keyword_names <- top_keywords_net$Keyword[1:30]
keyword_subgraph <- induced_subgraph(keyword_graph, V(keyword_graph)[name %in% top_keyword_names])

# Keep only edges with weight > threshold
edge_threshold <- quantile(E(keyword_subgraph)$weight, 0.5)
keyword_subgraph <- delete_edges(keyword_subgraph, 
                                 E(keyword_subgraph)[weight < edge_threshold])

# Detect communities
keyword_communities <- cluster_louvain(keyword_subgraph)
V(keyword_subgraph)$community <- membership(keyword_communities)

# Visualize with ggraph for better aesthetics
png("04_Results/Figures/keyword_cooccurrence_network.png", width = 4000, height = 4000, res = 300)

set.seed(456)
ggraph(keyword_subgraph, layout = "fr") +
  geom_edge_link(aes(width = weight), alpha = 0.3, color = "gray60") +
  geom_node_point(aes(size = degree(keyword_subgraph), 
                      color = as.factor(community)), 
                  alpha = 0.8) +
  geom_node_text(aes(label = name), size = 3, repel = TRUE) +
  scale_edge_width(range = c(0.5, 3)) +
  scale_size(range = c(3, 15)) +
  labs(title = "Keyword Co-occurrence Network",
       subtitle = "Top 30 keywords, sized by degree centrality") +
  theme_graph() +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    legend.position = "none"
  )

dev.off()
cat("   ✓ Keyword co-occurrence network plotted\n\n")

# ============================================================================
# CO-CITATION NETWORK
# ============================================================================

cat("4. Creating co-citation network...\n")

# Create co-citation network
cocit_net <- biblioNetwork(M,
                          analysis = "co-citation",
                          network = "references",
                          sep = ";")

# Convert to igraph
cocit_graph <- graph_from_adjacency_matrix(cocit_net,
                                          mode = "undirected",
                                          weighted = TRUE)

cat("   ✓ Co-citation network created\n")
cat("   Network size:", vcount(cocit_graph), "references,", ecount(cocit_graph), "co-citations\n")

# Get top cited references
cocit_degree <- degree(cocit_graph)
top_cocited <- data.frame(
  Reference = names(cocit_degree),
  Degree = cocit_degree
) %>%
  arrange(desc(Degree)) %>%
  head(30)

write.csv(top_cocited, "04_Results/Networks/cocitation_network_metrics.csv", row.names = FALSE)

# Filter to top 20 for visualization
top_cocited_names <- top_cocited$Reference[1:20]
cocit_subgraph <- induced_subgraph(cocit_graph, V(cocit_graph)[name %in% top_cocited_names])

# Detect communities
cocit_communities <- cluster_louvain(cocit_subgraph)
V(cocit_subgraph)$community <- membership(cocit_communities)

# Visualize
png("04_Results/Figures/cocitation_network.png", width = 4000, height = 4000, res = 300)

set.seed(789)
plot(cocit_subgraph,
     vertex.size = degree(cocit_subgraph) * 3,
     vertex.label.cex = 0.5,
     vertex.color = membership(cocit_communities),
     vertex.label.color = "black",
     vertex.frame.color = "white",
     edge.width = E(cocit_subgraph)$weight / 3,
     edge.color = "gray70",
     layout = layout_with_kk(cocit_subgraph),
     main = "Co-Citation Network (Top 20 References)")

dev.off()
cat("   ✓ Co-citation network plotted\n\n")

# ============================================================================
# COUNTRY COLLABORATION NETWORK
# ============================================================================

cat("5. Creating country collaboration network...\n")

# Extract country information
M_countries <- metaTagExtraction(M, Field = "AU_CO", sep = ";")

# Create country collaboration network
country_net <- biblioNetwork(M_countries,
                            analysis = "collaboration",
                            network = "countries",
                            sep = ";")

# Convert to igraph
country_graph <- graph_from_adjacency_matrix(country_net,
                                            mode = "undirected",
                                            weighted = TRUE)

cat("   ✓ Country collaboration network created\n")
cat("   Network size:", vcount(country_graph), "countries,", ecount(country_graph), "collaborations\n")

# Calculate metrics
country_degree <- degree(country_graph)
country_betweenness <- betweenness(country_graph)

top_countries_net <- data.frame(
  Country = names(country_degree),
  Degree = country_degree,
  Betweenness = country_betweenness
) %>%
  arrange(desc(Degree)) %>%
  head(20)

write.csv(top_countries_net, "04_Results/Networks/country_network_metrics.csv", row.names = FALSE)

# Detect communities
country_communities <- cluster_louvain(country_graph)
V(country_graph)$community <- membership(country_communities)

# Visualize
png("04_Results/Figures/country_collaboration_network.png", width = 3600, height = 3600, res = 300)

set.seed(321)
plot(country_graph,
     vertex.size = degree(country_graph) * 2,
     vertex.label.cex = 0.8,
     vertex.color = membership(country_communities),
     vertex.label.color = "black",
     vertex.frame.color = "white",
     edge.width = E(country_graph)$weight,
     edge.color = "gray60",
     layout = layout_with_fr(country_graph),
     main = "Country Collaboration Network")

dev.off()
cat("   ✓ Country collaboration network plotted\n\n")

# ============================================================================
# NETWORK STATISTICS SUMMARY
# ============================================================================

cat("6. Generating network statistics summary...\n")

network_summary <- data.frame(
  Network_Type = c("Co-Authorship", "Keyword Co-occurrence", 
                   "Co-Citation", "Country Collaboration"),
  Nodes = c(vcount(author_graph), vcount(keyword_graph),
            vcount(cocit_graph), vcount(country_graph)),
  Edges = c(ecount(author_graph), ecount(keyword_graph),
            ecount(cocit_graph), ecount(country_graph)),
  Density = c(
    round(edge_density(author_graph), 4),
    round(edge_density(keyword_graph), 4),
    round(edge_density(cocit_graph), 4),
    round(edge_density(country_graph), 4)
  ),
  Avg_Degree = c(
    round(mean(degree(author_graph)), 2),
    round(mean(degree(keyword_graph)), 2),
    round(mean(degree(cocit_graph)), 2),
    round(mean(degree(country_graph)), 2)
  ),
  Communities = c(
    length(unique(membership(cluster_louvain(author_graph)))),
    length(unique(membership(cluster_louvain(keyword_graph)))),
    length(unique(membership(cluster_louvain(cocit_graph)))),
    length(unique(membership(cluster_louvain(country_graph))))
  )
)

print(network_summary)
write.csv(network_summary, "04_Results/Networks/network_summary_statistics.csv", row.names = FALSE)
cat("   ✓ Network statistics summary saved\n\n")

# ============================================================================
# EXPORT NETWORKS FOR VOSVIEWER
# ============================================================================

cat("7. Preparing data for VOSviewer...\n")

# VOSviewer instructions
vosviewer_instructions <- "
====================================================================
INSTRUCTIONS FOR VOSVIEWER VISUALIZATION
====================================================================

VOSviewer provides superior network visualization for publications.

STEP 1: Download VOSviewer
- Visit: https://www.vosviewer.com/
- Download and extract (no installation needed)
- Run VOSviewer.jar

STEP 2: Import Data
- File → Create → Create a map based on bibliographic data
- Choose: 'Read data from bibliographic database files'
- Select file: 02_Processed_Data/for_vosviewer.txt
- Or use RIS format if available

STEP 3: Choose Analysis Type
For different analyses, select:
- Co-occurrence analysis → Author keywords
- Co-authorship analysis → Authors
- Co-citation analysis → Cited references
- Bibliographic coupling → Documents

STEP 4: Set Parameters
Recommended settings:
- Minimum occurrences/documents: 3-5
- Counting method: Full counting
- Number of items: 50-100

STEP 5: Visualize
- View: Network visualization (default)
- Overlay visualization (temporal patterns)
- Density visualization (research hotspots)

STEP 6: Customize
- Visualization → Colors → By cluster or By year
- Layout → Attraction/Repulsion (adjust spacing)
- Items → Show/hide items by threshold

STEP 7: Export
- File → Export → PNG (for publications, 300 DPI)
- File → Save map (to save and reload later)

====================================================================
NETWORK FILES READY FOR VOSVIEWER
====================================================================

Primary file: 02_Processed_Data/for_vosviewer.txt
This file contains all documents with full bibliographic information.

For best results:
1. Create separate networks for each analysis type
2. Save each network with descriptive name
3. Use overlay visualization to show temporal evolution
4. Export high-resolution images (3000+ pixels width)

====================================================================
"

writeLines(vosviewer_instructions, "04_Results/Networks/VOSviewer_Instructions.txt")
cat("   ✓ VOSviewer instructions saved\n")
cat("   ✓ Data file ready: 02_Processed_Data/for_vosviewer.txt\n\n")

# ============================================================================
# NETWORK VISUALIZATION COMPLETE
# ============================================================================

cat("=== NETWORK VISUALIZATION COMPLETE ===\n\n")
cat("Generated files:\n")
cat("  • Figures/coauthorship_network.png\n")
cat("  • Figures/keyword_cooccurrence_network.png\n")
cat("  • Figures/cocitation_network.png\n")
cat("  • Figures/country_collaboration_network.png\n")
cat("  • Networks/author_network_metrics.csv\n")
cat("  • Networks/keyword_network_metrics.csv\n")
cat("  • Networks/cocitation_network_metrics.csv\n")
cat("  • Networks/country_network_metrics.csv\n")
cat("  • Networks/network_summary_statistics.csv\n")
cat("  • Networks/VOSviewer_Instructions.txt\n")

cat("\nNetwork summary:\n")
print(network_summary)

cat("\nFor advanced visualization:\n")
cat("  1. Use VOSviewer (free software)\n")
cat("  2. Follow instructions in: Networks/VOSviewer_Instructions.txt\n")
cat("  3. Input file ready: 02_Processed_Data/for_vosviewer.txt\n")

cat("\nNext step: Run 09_stbm_synthesis.R (final integration)\n")
