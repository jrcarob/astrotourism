# ============================================================================
# STBM ANALYSIS - STEP 07: SEMANTIC ANALYSIS (STBM DISTINCTIVE COMPONENT)
# ============================================================================
# Purpose: Identify semantic fields, paradigms, and integration patterns
# Prerequisites: Final clean dataset and thematic analysis results
# This is THE DISTINCTIVE COMPONENT of STBM methodology
# ============================================================================

# Load required libraries
library(dplyr)
library(stringr)
library(tidyr)
library(ggplot2)

cat("=== SEMANTIC ANALYSIS (STBM DISTINCTIVE) ===\n\n")

# ============================================================================
# LOAD DATASET AND KEYWORDS
# ============================================================================

cat("1. Loading dataset and extracting keywords...\n")
load("02_Processed_Data/final_dataset_clean.RData")
M <- final_data_clean

# Load keyword frequencies from descriptive analysis
keywords_de <- read.csv("04_Results/12_Authors_Keywords.csv")

cat("   ✓ Dataset loaded:", nrow(M), "documents\n")
cat("   ✓ Unique keywords:", nrow(keywords_de), "\n\n")

# ============================================================================
# SEMANTIC FIELD CODING FUNCTION
# ============================================================================

cat("2. Defining semantic field coding rules...\n")

# Function to assign semantic fields based on keyword content
code_semantic_field <- function(keyword) {
  keyword_lower <- tolower(trimws(keyword))
  
  # Environmental-Scientific Domain
  if(grepl("light pollution|dark sky|night sky|sky quality|atmospheric|conservation|protected area|environment|pollution|sky brightness|light trespass", keyword_lower)) {
    return(list(
      Field = "Environmental-Scientific",
      Domain = "Conservation Science",
      Paradigm = "Conservation"
    ))
  }
  
  # Tourism-Commercial Domain
  if(grepl("tourism|tourist|visitor|destination|marketing|experience|satisfaction|attraction|hotel|accommodation|travel|recreation|leisure|hospitality", keyword_lower)) {
    return(list(
      Field = "Tourism-Commercial",
      Domain = "Tourism Studies",
      Paradigm = "Development"
    ))
  }
  
  # Sustainability-Development Domain
  if(grepl("sustainab|rural development|community|stakeholder|impact assessment|development|livelihood|economic|social|triple bottom", keyword_lower)) {
    return(list(
      Field = "Sustainability-Development",
      Domain = "Sustainable Development",
      Paradigm = "Sustainability"
    ))
  }
  
  # Heritage-Cultural Domain
  if(grepl("heritage|cultural|authenticit|indigenous|interpretation|identity|meaning|tradition|local knowledge|archaeo|mythology|folklore|indigenous", keyword_lower)) {
    return(list(
      Field = "Heritage-Cultural",
      Domain = "Heritage Studies",
      Paradigm = "Cultural"
    ))
  }
  
  # Governance-Policy Domain
  if(grepl("policy|governance|regulation|certification|designation|management|planning|legislation|law|standard|framework|institutional|administration", keyword_lower)) {
    return(list(
      Field = "Governance-Policy",
      Domain = "Public Policy",
      Paradigm = "Governance"
    ))
  }
  
  # Default for unclassified
  return(list(
    Field = "Other/Mixed",
    Domain = "Unclassified",
    Paradigm = "Mixed"
  ))
}

cat("   ✓ Semantic coding rules defined\n")
cat("   Identified semantic fields:\n")
cat("     1. Environmental-Scientific\n")
cat("     2. Tourism-Commercial\n")
cat("     3. Sustainability-Development\n")
cat("     4. Heritage-Cultural\n")
cat("     5. Governance-Policy\n\n")

# ============================================================================
# APPLY SEMANTIC CODING TO ALL KEYWORDS
# ============================================================================

cat("3. Applying semantic coding to all keywords...\n")

# Create semantic field assignments
semantic_fields <- data.frame(
  Keyword = keywords_de$Keyword,
  Occurrences = keywords_de$Occurrences,
  Semantic_Field = NA,
  Domain = NA,
  Paradigm = NA,
  stringsAsFactors = FALSE
)

# Apply coding to each keyword
for(i in 1:nrow(semantic_fields)) {
  coding <- code_semantic_field(semantic_fields$Keyword[i])
  semantic_fields$Semantic_Field[i] <- coding$Field
  semantic_fields$Domain[i] <- coding$Domain
  semantic_fields$Paradigm[i] <- coding$Paradigm
}

cat("   ✓ Coded", nrow(semantic_fields), "keywords\n")

# Save semantic field coding
write.csv(semantic_fields, "04_Results/22_Semantic_Field_Coding.csv", row.names = FALSE)
cat("   ✓ Semantic field coding saved\n\n")

# ============================================================================
# SEMANTIC FIELD STATISTICS
# ============================================================================

cat("4. Calculating semantic field statistics...\n")

semantic_stats <- semantic_fields %>%
  group_by(Semantic_Field) %>%
  summarise(
    Keywords = n(),
    Total_Occurrences = sum(Occurrences),
    Avg_Occurrences = round(mean(Occurrences), 2),
    .groups = "drop"
  ) %>%
  mutate(
    Percentage_Keywords = round(100 * Keywords / sum(Keywords), 1),
    Percentage_Occurrences = round(100 * Total_Occurrences / sum(Total_Occurrences), 1)
  ) %>%
  arrange(desc(Total_Occurrences))

print(semantic_stats)
write.csv(semantic_stats, "04_Results/23_Semantic_Field_Statistics.csv", row.names = FALSE)
cat("\n   ✓ Semantic field statistics saved\n\n")

# Visualize semantic field distribution
p_semantic <- ggplot(semantic_stats %>% filter(Semantic_Field != "Other/Mixed"), 
                     aes(x = reorder(Semantic_Field, Total_Occurrences), 
                         y = Total_Occurrences, 
                         fill = Semantic_Field)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Distribution of Semantic Fields",
       subtitle = "By Total Keyword Occurrences",
       x = "Semantic Field",
       y = "Total Occurrences") +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    legend.position = "none"
  ) +
  scale_fill_brewer(palette = "Set2")

ggsave("04_Results/Figures/semantic_field_distribution.png", 
       p_semantic, width = 10, height = 6, dpi = 300)
cat("   ✓ Semantic field distribution plotted\n\n")

# ============================================================================
# PARADIGM EVOLUTION OVER TIME
# ============================================================================

cat("5. Analyzing paradigm evolution over time...\n")

# Extract documents with keywords and assign paradigms
paradigm_evolution <- M %>%
  filter(!is.na(DE) & DE != "") %>%
  select(SR, PY, DE) %>%
  mutate(keywords = strsplit(as.character(DE), ";")) %>%
  unnest(keywords) %>%
  mutate(keywords = trimws(tolower(keywords))) %>%
  left_join(
    semantic_fields %>% select(Keyword, Paradigm),
    by = c("keywords" = "Keyword")
  ) %>%
  filter(!is.na(Paradigm) & Paradigm != "Mixed")

# Count by year and paradigm
paradigm_by_year <- paradigm_evolution %>%
  group_by(PY, Paradigm) %>%
  summarise(Count = n(), .groups = "drop")

# Calculate proportions
paradigm_proportions <- paradigm_by_year %>%
  group_by(PY) %>%
  mutate(
    Total = sum(Count),
    Proportion = round(100 * Count / Total, 2)
  ) %>%
  ungroup()

write.csv(paradigm_proportions, "04_Results/24_Paradigm_Evolution.csv", row.names = FALSE)
cat("   ✓ Paradigm evolution data saved\n")

# Visualize paradigm evolution
p_paradigm <- ggplot(paradigm_proportions, 
                     aes(x = PY, y = Proportion, fill = Paradigm)) +
  geom_area(alpha = 0.7, position = "stack") +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Paradigmatic Evolution Over Time",
       subtitle = "Proportion of Research Paradigms by Year",
       x = "Year",
       y = "Proportion (%)",
       fill = "Paradigm") +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5),
    legend.position = "bottom"
  )

ggsave("04_Results/Figures/paradigm_evolution.png", 
       p_paradigm, width = 12, height = 7, dpi = 300)
cat("   ✓ Paradigm evolution plotted\n\n")

# ============================================================================
# SEMANTIC INTEGRATION ANALYSIS
# ============================================================================

cat("6. Analyzing semantic integration patterns...\n")

# Analyze which semantic fields co-occur in documents
semantic_cooccurrence <- M %>%
  filter(!is.na(DE) & DE != "") %>%
  select(SR, DE) %>%
  mutate(keywords = strsplit(as.character(DE), ";")) %>%
  unnest(keywords) %>%
  mutate(keywords = trimws(tolower(keywords))) %>%
  left_join(
    semantic_fields %>% select(Keyword, Semantic_Field),
    by = c("keywords" = "Keyword")
  ) %>%
  filter(!is.na(Semantic_Field) & Semantic_Field != "Other/Mixed") %>%
  group_by(SR) %>%
  summarise(
    Fields = paste(sort(unique(Semantic_Field)), collapse = "; "),
    Field_Count = length(unique(Semantic_Field)),
    .groups = "drop"
  )

# Calculate integration patterns
integration_patterns <- semantic_cooccurrence %>%
  group_by(Fields) %>%
  summarise(Documents = n(), .groups = "drop") %>%
  arrange(desc(Documents)) %>%
  head(20)

write.csv(integration_patterns, "04_Results/25_Semantic_Integration_Patterns.csv", row.names = FALSE)
cat("   ✓ Integration patterns saved (top 20)\n")

# Calculate integration index
integration_index <- mean(semantic_cooccurrence$Field_Count, na.rm = TRUE)

cat("   ✓ Semantic Integration Index:", round(integration_index, 2), "fields per document\n")
cat("     (Higher values indicate more interdisciplinary integration)\n\n")

# Integration frequency
integration_freq <- as.data.frame(table(semantic_cooccurrence$Field_Count))
names(integration_freq) <- c("Number_of_Fields", "Documents")

cat("   Distribution of field integration:\n")
print(integration_freq)
cat("\n")

# ============================================================================
# SEMANTIC FIELD CO-OCCURRENCE MATRIX
# ============================================================================

cat("7. Creating semantic field co-occurrence matrix...\n")

# Extract documents with multiple fields
multi_field_docs <- M %>%
  filter(!is.na(DE) & DE != "") %>%
  select(SR, DE) %>%
  mutate(keywords = strsplit(as.character(DE), ";")) %>%
  unnest(keywords) %>%
  mutate(keywords = trimws(tolower(keywords))) %>%
  left_join(
    semantic_fields %>% select(Keyword, Semantic_Field),
    by = c("keywords" = "Keyword")
  ) %>%
  filter(!is.na(Semantic_Field) & Semantic_Field != "Other/Mixed")

# Create co-occurrence matrix
field_names <- unique(multi_field_docs$Semantic_Field)
co_matrix <- matrix(0, nrow = length(field_names), ncol = length(field_names))
rownames(co_matrix) <- field_names
colnames(co_matrix) <- field_names

# Count co-occurrences
docs_by_field <- multi_field_docs %>%
  group_by(SR, Semantic_Field) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = Semantic_Field, values_from = n, values_fill = 0)

for(i in 1:length(field_names)) {
  for(j in 1:length(field_names)) {
    if(i != j) {
      field_i <- field_names[i]
      field_j <- field_names[j]
      
      if(field_i %in% names(docs_by_field) && field_j %in% names(docs_by_field)) {
        co_matrix[i, j] <- sum(docs_by_field[[field_i]] > 0 & docs_by_field[[field_j]] > 0)
      }
    }
  }
}

# Convert to data frame for saving
co_matrix_df <- as.data.frame(co_matrix)
co_matrix_df$Field <- rownames(co_matrix_df)
co_matrix_df <- co_matrix_df[, c("Field", field_names)]

write.csv(co_matrix_df, "04_Results/semantic_field_cooccurrence_matrix.csv", row.names = FALSE)
cat("   ✓ Semantic field co-occurrence matrix saved\n\n")

# ============================================================================
# IDENTIFY SEMANTIC DISCONNECTIONS (RESEARCH GAPS)
# ============================================================================

cat("8. Identifying semantic disconnections (potential research gaps)...\n")

# Find field pairs with low co-occurrence relative to their individual frequencies
field_totals <- semantic_stats %>%
  filter(Semantic_Field != "Other/Mixed") %>%
  select(Semantic_Field, Total_Occurrences)

disconnections <- data.frame(
  Field1 = character(),
  Field2 = character(),
  Expected_Cooccurrence = numeric(),
  Actual_Cooccurrence = numeric(),
  Disconnect_Score = numeric(),
  stringsAsFactors = FALSE
)

for(i in 1:(length(field_names)-1)) {
  for(j in (i+1):length(field_names)) {
    field_i <- field_names[i]
    field_j <- field_names[j]
    
    freq_i <- field_totals$Total_Occurrences[field_totals$Semantic_Field == field_i]
    freq_j <- field_totals$Total_Occurrences[field_totals$Semantic_Field == field_j]
    
    if(length(freq_i) > 0 && length(freq_j) > 0) {
      expected <- sqrt(freq_i * freq_j) / 10  # Simple expectation formula
      actual <- co_matrix[field_i, field_j]
      disconnect <- expected - actual
      
      if(disconnect > 5) {  # Threshold for significant disconnection
        disconnections <- rbind(disconnections, data.frame(
          Field1 = field_i,
          Field2 = field_j,
          Expected_Cooccurrence = round(expected, 1),
          Actual_Cooccurrence = actual,
          Disconnect_Score = round(disconnect, 1)
        ))
      }
    }
  }
}

disconnections <- disconnections %>% arrange(desc(Disconnect_Score))

if(nrow(disconnections) > 0) {
  write.csv(disconnections, "04_Results/semantic_disconnections_gaps.csv", row.names = FALSE)
  cat("   ✓ Found", nrow(disconnections), "semantic disconnections\n")
  cat("   These represent underexplored field combinations\n\n")
} else {
  cat("   • No major semantic disconnections detected\n\n")
}

# ============================================================================
# SEMANTIC ANALYSIS SUMMARY REPORT
# ============================================================================

cat("9. Generating semantic analysis summary report...\n")

sink("04_Results/semantic_analysis_summary.txt")
cat("====================================================================\n")
cat("SEMANTIC ANALYSIS SUMMARY REPORT\n")
cat("====================================================================\n\n")

cat("ANALYSIS DATE:", format(Sys.Date(), "%B %d, %Y"), "\n")
cat("DATASET SIZE:", nrow(M), "documents\n\n")

cat("--------------------------------------------------------------------\n")
cat("SEMANTIC FIELDS IDENTIFIED\n")
cat("--------------------------------------------------------------------\n\n")

for(i in 1:nrow(semantic_stats)) {
  cat(semantic_stats$Semantic_Field[i], "\n")
  cat("  Keywords:", semantic_stats$Keywords[i], 
      "(", semantic_stats$Percentage_Keywords[i], "% of total)\n")
  cat("  Occurrences:", semantic_stats$Total_Occurrences[i],
      "(", semantic_stats$Percentage_Occurrences[i], "% of total)\n")
  cat("  Average occurrences per keyword:", semantic_stats$Avg_Occurrences[i], "\n\n")
}

cat("--------------------------------------------------------------------\n")
cat("PARADIGMATIC STRUCTURE\n")
cat("--------------------------------------------------------------------\n\n")

paradigm_summary <- paradigm_proportions %>%
  group_by(Paradigm) %>%
  summarise(
    Total_Count = sum(Count),
    Avg_Proportion = round(mean(Proportion), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Count))

for(i in 1:nrow(paradigm_summary)) {
  cat(paradigm_summary$Paradigm[i], "\n")
  cat("  Total appearances:", paradigm_summary$Total_Count[i], "\n")
  cat("  Average proportion:", paradigm_summary$Avg_Proportion[i], "%\n\n")
}

cat("--------------------------------------------------------------------\n")
cat("INTEGRATION ANALYSIS\n")
cat("--------------------------------------------------------------------\n\n")

cat("Semantic Integration Index:", round(integration_index, 2), "fields per document\n\n")

cat("Integration patterns (top 5):\n")
for(i in 1:min(5, nrow(integration_patterns))) {
  cat("  ", integration_patterns$Fields[i], ":", 
      integration_patterns$Documents[i], "documents\n")
}

cat("\n")

if(nrow(disconnections) > 0) {
  cat("--------------------------------------------------------------------\n")
  cat("SEMANTIC DISCONNECTIONS (Research Opportunities)\n")
  cat("--------------------------------------------------------------------\n\n")
  
  cat("Field pairs with unexpectedly low integration:\n\n")
  for(i in 1:min(5, nrow(disconnections))) {
    cat(i, ". ", disconnections$Field1[i], " <--> ", disconnections$Field2[i], "\n")
    cat("   Disconnect Score:", disconnections$Disconnect_Score[i], "\n")
    cat("   Interpretation: These fields rarely appear together despite\n")
    cat("   their individual prominence, suggesting research gap\n\n")
  }
}

cat("====================================================================\n")
cat("END OF SEMANTIC ANALYSIS SUMMARY\n")
cat("====================================================================\n")

sink()

cat("   ✓ Summary report saved\n\n")

# ============================================================================
# SEMANTIC ANALYSIS COMPLETE
# ============================================================================

cat("=== SEMANTIC ANALYSIS COMPLETE ===\n\n")
cat("Generated files:\n")
cat("  • 22_Semantic_Field_Coding.csv\n")
cat("  • 23_Semantic_Field_Statistics.csv\n")
cat("  • 24_Paradigm_Evolution.csv\n")
cat("  • 25_Semantic_Integration_Patterns.csv\n")
cat("  • semantic_field_cooccurrence_matrix.csv\n")
cat("  • semantic_disconnections_gaps.csv (if gaps found)\n")
cat("  • semantic_analysis_summary.txt\n")
cat("  • Figures/semantic_field_distribution.png\n")
cat("  • Figures/paradigm_evolution.png\n")

cat("\nKey findings:\n")
cat("  • Dominant semantic field:", semantic_stats$Semantic_Field[1], "\n")
cat("  • Integration index:", round(integration_index, 2), "fields/document\n")
cat("  • Semantic disconnections found:", nrow(disconnections), "\n")

cat("\nNext step: Run 08_network_visualization.R\n")
