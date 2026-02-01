# ============================================================================
# STBM ANALYSIS - STEP 06: THEMATIC ANALYSIS (STBM CORE)
# ============================================================================
# Purpose: Co-word analysis, strategic diagrams, thematic evolution
# Prerequisites: Final clean dataset from step 04
# This is a KEY component of STBM methodology
# ============================================================================

# Load required libraries
library(bibliometrix)
library(dplyr)
library(ggplot2)
library(igraph)

cat("=== THEMATIC ANALYSIS (STBM CORE) ===\n\n")

# ============================================================================
# LOAD DATASET
# ============================================================================

cat("1. Loading dataset...\n")
load("02_Processed_Data/final_dataset_clean.RData")
M <- final_data_clean
cat("   ✓ Loaded:", nrow(M), "documents\n\n")

# ============================================================================
# CO-WORD ANALYSIS - KEYWORD CO-OCCURRENCE NETWORK
# ============================================================================

cat("2. Creating keyword co-occurrence network...\n")

# Create co-occurrence matrix
NetMatrix <- biblioNetwork(M, 
                          analysis = "co-occurrences", 
                          network = "keywords", 
                          sep = ";")

cat("   ✓ Network created with", nrow(NetMatrix), "keywords\n")

# Calculate network statistics
net_stats <- networkStat(NetMatrix)

# Save network statistics
sink("04_Results/16_Coword_Network_Statistics.txt")
cat("CO-WORD NETWORK STATISTICS\n")
cat("==========================\n\n")
cat("Number of nodes (keywords):", net_stats$network$n, "\n")
cat("Number of edges:", net_stats$network$m, "\n")
cat("Network density:", round(net_stats$network$density, 4), "\n")
cat("Average degree:", round(net_stats$network$degree_mean, 2), "\n")
cat("Network transitivity:", round(net_stats$network$transitivity, 4), "\n")
sink()

cat("   ✓ Network statistics saved\n\n")

# ============================================================================
# KEYWORD CORRELATION ANALYSIS
# ============================================================================

cat("3. Calculating keyword correlations...\n")

# Normalize network for correlation
NetMatrix_norm <- normalizeSimilarity(NetMatrix, type = "association")

# Calculate correlations
keyword_cor <- cor(as.matrix(NetMatrix_norm), method = "pearson")

# Extract high correlations
cor_threshold <- 0.3
high_cor_indices <- which(keyword_cor > cor_threshold & keyword_cor < 1, arr.ind = TRUE)

if(nrow(high_cor_indices) > 0) {
  correlations_df <- data.frame(
    Keyword1 = rownames(keyword_cor)[high_cor_indices[,1]],
    Keyword2 = colnames(keyword_cor)[high_cor_indices[,2]],
    Correlation = keyword_cor[high_cor_indices]
  ) %>%
    filter(Keyword1 < Keyword2) %>%  # Remove duplicates
    arrange(desc(Correlation)) %>%
    head(100)
  
  write.csv(correlations_df, "04_Results/17_Keyword_Correlations.csv", row.names = FALSE)
  cat("   ✓ Top 100 keyword correlations saved\n\n")
} else {
  cat("   ⚠ No correlations above threshold", cor_threshold, "\n\n")
}

# ============================================================================
# STRATEGIC DIAGRAM (THEMATIC MAP) - STBM SIGNATURE ANALYSIS
# ============================================================================

cat("4. Generating strategic diagram (thematic map)...\n")
cat("   This may take 1-3 minutes...\n")

# Generate thematic map
thematic_map <- thematicMap(M, 
                           field = "DE",           # Author keywords
                           n = 250,                # Max keywords to analyze
                           minfreq = 3,            # Minimum frequency
                           stemming = FALSE,       # Don't stem words
                           size = 0.5,             # Cluster label size
                           n.labels = 5,           # Labels per cluster
                           repel = TRUE)           # Repel labels

cat("   ✓ Thematic map generated\n")

# Extract cluster information
clusters <- thematic_map$clusters

# Assign quadrant labels
clusters <- clusters %>%
  mutate(
    Quadrant_Label = case_when(
      Quadrant == 1 ~ "Motor Themes (High Cent, High Dens)",
      Quadrant == 2 ~ "Niche Themes (Low Cent, High Dens)",
      Quadrant == 3 ~ "Emerging/Declining (Low Cent, Low Dens)",
      Quadrant == 4 ~ "Basic Themes (High Cent, Low Dens)",
      TRUE ~ "Other"
    )
  )

# Save cluster data
write.csv(clusters, "04_Results/18_Thematic_Clusters.csv", row.names = FALSE)
cat("   ✓ Cluster data saved\n")

# Summarize by quadrant
quadrant_summary <- clusters %>%
  group_by(Quadrant, Quadrant_Label) %>%
  summarise(
    Themes = n(),
    Avg_Centrality = round(mean(Centrality), 3),
    Avg_Density = round(mean(Density), 3),
    Total_Keywords = sum(Freq),
    .groups = "drop"
  ) %>%
  arrange(Quadrant)

print(quadrant_summary)
write.csv(quadrant_summary, "04_Results/19_Strategic_Diagram_Quadrants.csv", row.names = FALSE)
cat("   ✓ Quadrant summary saved\n")

# Plot strategic diagram
png("04_Results/Figures/strategic_diagram.png", width = 3000, height = 2400, res = 300)
plot(thematic_map$map)
dev.off()
cat("   ✓ Strategic diagram plotted\n\n")

# ============================================================================
# THEMATIC EVOLUTION
# ============================================================================

cat("5. Analyzing thematic evolution...\n")
cat("   This may take 2-4 minutes...\n")

# Define time periods (adjust based on your data)
# Calculate year breaks to create roughly equal periods
years_range <- range(M$PY, na.rm = TRUE)
period1 <- c(years_range[1], years_range[1] + floor((years_range[2] - years_range[1]) / 3))
period2 <- c(period1[2] + 1, period1[2] + floor((years_range[2] - years_range[1]) / 3))
period3 <- c(period2[2] + 1, years_range[2])

years_labels <- c(
  paste0(period1[1], "-", period1[2]),
  paste0(period2[1], "-", period2[2]),
  paste0(period3[1], "-", period3[2])
)

cat("   Time periods:", paste(years_labels, collapse = " | "), "\n")

# Create thematic evolution
nexus <- thematicEvolution(M, 
                          field = "DE", 
                          years = years_labels,
                          n = 100,
                          minFreq = 2)

# Save evolution data
write.csv(nexus$Data, "04_Results/20_Thematic_Evolution.csv", row.names = FALSE)
cat("   ✓ Thematic evolution data saved\n")

# Plot evolution
png("04_Results/Figures/thematic_evolution.png", width = 3600, height = 2400, res = 300)
plotThematicEvolution(nexus$Nodes, nexus$Edges)
dev.off()
cat("   ✓ Thematic evolution plotted\n\n")

# ============================================================================
# CONCEPTUAL STRUCTURE - MULTIPLE CORRESPONDENCE ANALYSIS
# ============================================================================

cat("6. Analyzing conceptual structure (MCA)...\n")
cat("   This may take 2-3 minutes...\n")

# Conceptual structure map
CS <- conceptualStructure(M, 
                         field = "DE",
                         method = "MCA",
                         minDegree = 3,
                         clust = 5,
                         stemming = FALSE,
                         labelsize = 10,
                         documents = 20)

cat("   ✓ Conceptual structure analyzed\n")

# Extract cluster assignments
concept_clusters <- data.frame(
  Keyword = names(CS$km.res$cluster),
  Cluster = CS$km.res$cluster
) %>%
  arrange(Cluster, Keyword)

write.csv(concept_clusters, "04_Results/21_Conceptual_Clusters_MCA.csv", row.names = FALSE)
cat("   ✓ Conceptual clusters saved\n")

# Save conceptual map
png("04_Results/Figures/conceptual_structure_map.png", width = 3000, height = 2400, res = 300)
plot(CS$graph_terms)
dev.off()
cat("   ✓ Conceptual structure map plotted\n\n")

# ============================================================================
# IDENTIFY RESEARCH GAPS (BASIC THEMES)
# ============================================================================

cat("7. Identifying research gaps from basic themes...\n")

basic_themes <- clusters %>%
  filter(Quadrant == 4) %>%  # Quadrant 4 = Basic themes
  arrange(desc(Centrality)) %>%
  select(cluster_label, words, Centrality, Density, Freq)

if(nrow(basic_themes) > 0) {
  write.csv(basic_themes, "04_Results/27_Knowledge_Gaps_Basic_Themes.csv", row.names = FALSE)
  cat("   ✓ Found", nrow(basic_themes), "basic themes (high centrality, low density)\n")
  cat("   These represent important but underdeveloped areas\n\n")
} else {
  cat("   • No basic themes identified in this dataset\n\n")
}

# ============================================================================
# IDENTIFY EMERGING THEMES
# ============================================================================

cat("8. Identifying emerging themes...\n")

emerging_themes <- clusters %>%
  filter(Quadrant == 3) %>%  # Quadrant 3 = Emerging/Declining
  arrange(desc(Freq)) %>%
  select(cluster_label, words, Centrality, Density, Freq)

if(nrow(emerging_themes) > 0) {
  write.csv(emerging_themes, "04_Results/emerging_themes.csv", row.names = FALSE)
  cat("   ✓ Found", nrow(emerging_themes), "emerging/declining themes\n\n")
} else {
  cat("   • No emerging themes identified in this dataset\n\n")
}

# ============================================================================
# KEYWORD GROWTH ANALYSIS
# ============================================================================

cat("9. Analyzing keyword growth over time...\n")

# Extract keywords by year
keyword_by_year <- M %>%
  filter(!is.na(DE) & DE != "" & !is.na(PY)) %>%
  select(PY, DE) %>%
  mutate(keywords = strsplit(as.character(DE), ";")) %>%
  tidyr::unnest(keywords) %>%
  mutate(keywords = trimws(tolower(keywords))) %>%
  group_by(PY, keywords) %>%
  summarise(Occurrences = n(), .groups = "drop") %>%
  arrange(PY, desc(Occurrences))

write.csv(keyword_by_year, "04_Results/15_Keyword_Growth_by_Year.csv", row.names = FALSE)
cat("   ✓ Keyword growth data saved\n\n")

# ============================================================================
# THEMATIC ANALYSIS SUMMARY
# ============================================================================

cat("=== THEMATIC ANALYSIS COMPLETE ===\n\n")
cat("Generated files:\n")
cat("  • 16_Coword_Network_Statistics.txt\n")
cat("  • 17_Keyword_Correlations.csv\n")
cat("  • 18_Thematic_Clusters.csv\n")
cat("  • 19_Strategic_Diagram_Quadrants.csv\n")
cat("  • 20_Thematic_Evolution.csv\n")
cat("  • 21_Conceptual_Clusters_MCA.csv\n")
cat("  • 27_Knowledge_Gaps_Basic_Themes.csv\n")
cat("  • 15_Keyword_Growth_by_Year.csv\n")
cat("  • Figures/strategic_diagram.png\n")
cat("  • Figures/thematic_evolution.png\n")
cat("  • Figures/conceptual_structure_map.png\n")

cat("\nKey findings:\n")
cat("  • Motor themes:", sum(quadrant_summary$Quadrant == 1), "\n")
cat("  • Basic themes (gaps):", sum(quadrant_summary$Quadrant == 4), "\n")
cat("  • Emerging themes:", sum(quadrant_summary$Quadrant == 3), "\n")
cat("  • Niche themes:", sum(quadrant_summary$Quadrant == 2), "\n")

cat("\nNext step: Run 07_semantic_analysis.R (STBM distinctive component)\n")
