# ============================================================================
# STBM ANALYSIS - STEP 05: DESCRIPTIVE ANALYSIS
# ============================================================================
# Purpose: Generate comprehensive descriptive statistics
# Prerequisites: Final clean dataset from step 04
# ============================================================================

# Load required libraries
library(bibliometrix)
library(dplyr)
library(ggplot2)

cat("=== DESCRIPTIVE BIBLIOMETRIC ANALYSIS ===\n\n")

# ============================================================================
# LOAD CLEAN DATASET
# ============================================================================

cat("1. Loading final clean dataset...\n")
load("02_Processed_Data/final_dataset_clean.RData")

M <- final_data_clean
cat("   ✓ Dataset loaded:", nrow(M), "documents\n")
cat("   ✓ Timespan:", min(M$PY, na.rm = TRUE), "-", max(M$PY, na.rm = TRUE), "\n\n")

# ============================================================================
# MAIN INFORMATION TABLE
# ============================================================================

cat("2. Generating main information table...\n")

results <- biblioAnalysis(M, sep = ";")

# Extract main information
main_info <- data.frame(
  Description = character(),
  Results = character(),
  stringsAsFactors = FALSE
)

# Document info
main_info <- rbind(main_info, data.frame(
  Description = "DOCUMENTS",
  Results = as.character(nrow(M))
))

main_info <- rbind(main_info, data.frame(
  Description = "TIMESPAN",
  Results = paste0(min(M$PY, na.rm = TRUE), ":", max(M$PY, na.rm = TRUE))
))

main_info <- rbind(main_info, data.frame(
  Description = "SOURCES (Journals, Books, etc.)",
  Results = as.character(length(unique(M$SO)))
))

main_info <- rbind(main_info, data.frame(
  Description = "AVERAGE YEARS FROM PUBLICATION",
  Results = as.character(round(2024 - mean(M$PY, na.rm = TRUE), 2))
))

main_info <- rbind(main_info, data.frame(
  Description = "AVERAGE CITATIONS PER DOCUMENT",
  Results = as.character(round(mean(M$TC, na.rm = TRUE), 2))
))

main_info <- rbind(main_info, data.frame(
  Description = "REFERENCES",
  Results = as.character(sum(stringr::str_count(M$CR, ";") + 1, na.rm = TRUE))
))

# Document types
if("DT" %in% names(M)) {
  doc_types <- table(M$DT)
  for(dt in names(doc_types)) {
    main_info <- rbind(main_info, data.frame(
      Description = toupper(dt),
      Results = as.character(doc_types[dt])
    ))
  }
}

# Authors
n_authors <- length(unique(unlist(strsplit(M$AU, ";"))))
main_info <- rbind(main_info, data.frame(
  Description = "AUTHORS",
  Results = as.character(n_authors)
))

n_appearances <- sum(stringr::str_count(M$AU, ";") + 1, na.rm = TRUE)
main_info <- rbind(main_info, data.frame(
  Description = "AUTHOR APPEARANCES",
  Results = as.character(n_appearances)
))

single_authored <- sum(stringr::str_count(M$AU, ";") == 0, na.rm = TRUE)
main_info <- rbind(main_info, data.frame(
  Description = "SINGLE-AUTHORED DOCUMENTS",
  Results = as.character(single_authored)
))

main_info <- rbind(main_info, data.frame(
  Description = "DOCUMENTS PER AUTHOR",
  Results = as.character(round(nrow(M) / n_authors, 3))
))

main_info <- rbind(main_info, data.frame(
  Description = "AUTHORS PER DOCUMENT",
  Results = as.character(round(n_appearances / nrow(M), 2))
))

main_info <- rbind(main_info, data.frame(
  Description = "CO-AUTHORS PER DOCUMENT",
  Results = as.character(round(mean(stringr::str_count(M$AU, ";") + 1, na.rm = TRUE), 2))
))

write.csv(main_info, "04_Results/01_Main_Information.csv", row.names = FALSE)
cat("   ✓ Main information table saved\n\n")

# ============================================================================
# ANNUAL SCIENTIFIC PRODUCTION
# ============================================================================

cat("3. Analyzing annual scientific production...\n")

annual_production <- M %>%
  group_by(PY) %>%
  summarise(Articles = n()) %>%
  arrange(PY) %>%
  mutate(
    Cumulative = cumsum(Articles),
    Growth_Rate = (Articles / lag(Articles) - 1) * 100
  )

write.csv(annual_production, "04_Results/02_Annual_Scientific_Production.csv", row.names = FALSE)

# Visualize
p1 <- ggplot(annual_production, aes(x = PY, y = Articles)) +
  geom_area(fill = "#3B82F6", alpha = 0.6) +
  geom_line(color = "#1E40AF", size = 1.2) +
  geom_point(color = "#1E40AF", size = 2.5) +
  labs(title = "Annual Scientific Production",
       x = "Year", y = "Number of Articles") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14, hjust = 0.5))

ggsave("04_Results/Figures/annual_production.png", p1, width = 10, height = 6, dpi = 300)
cat("   ✓ Annual production analyzed and plotted\n\n")

# ============================================================================
# MOST RELEVANT SOURCES
# ============================================================================

cat("4. Analyzing most relevant sources...\n")

source_analysis <- M %>%
  group_by(SO) %>%
  summarise(
    Articles = n(),
    Total_Citations = sum(TC, na.rm = TRUE),
    Avg_Citations = round(mean(TC, na.rm = TRUE), 2)
  ) %>%
  arrange(desc(Articles)) %>%
  mutate(Rank = row_number()) %>%
  head(20)

write.csv(source_analysis, "04_Results/03_Most_Relevant_Sources.csv", row.names = FALSE)
cat("   ✓ Top 20 sources identified\n\n")

# ============================================================================
# MOST PROLIFIC AUTHORS
# ============================================================================

cat("5. Analyzing most prolific authors...\n")

author_list <- unlist(strsplit(M$AU, ";"))
author_freq <- as.data.frame(table(trimws(author_list)))
names(author_freq) <- c("Author", "Articles")

author_freq <- author_freq %>%
  arrange(desc(Articles)) %>%
  mutate(Rank = row_number()) %>%
  head(20)

write.csv(author_freq, "04_Results/05_Most_Relevant_Authors.csv", row.names = FALSE)
cat("   ✓ Top 20 authors identified\n\n")

# ============================================================================
# MOST CITED DOCUMENTS
# ============================================================================

cat("6. Analyzing most cited documents...\n")

most_cited <- M %>%
  arrange(desc(TC)) %>%
  select(AU, PY, TI, SO, TC, DI) %>%
  head(20) %>%
  mutate(Rank = row_number())

write.csv(most_cited, "04_Results/08_Most_Cited_Documents.csv", row.names = FALSE)
cat("   ✓ Top 20 most cited documents identified\n\n")

# ============================================================================
# KEYWORD ANALYSIS
# ============================================================================

cat("7. Analyzing keywords...\n")

# Author keywords
if("DE" %in% names(M)) {
  keywords_de <- unlist(strsplit(M$DE[!is.na(M$DE) & M$DE != ""], ";"))
  keywords_de <- trimws(tolower(keywords_de))
  
  keywords_freq <- as.data.frame(table(keywords_de))
  names(keywords_freq) <- c("Keyword", "Occurrences")
  
  keywords_freq <- keywords_freq %>%
    arrange(desc(Occurrences)) %>%
    mutate(
      Rank = row_number(),
      Percentage = round(100 * Occurrences / nrow(M), 2)
    ) %>%
    head(50)
  
  write.csv(keywords_freq, "04_Results/12_Authors_Keywords.csv", row.names = FALSE)
  cat("   ✓ Top 50 author keywords identified\n")
}

# Keywords Plus
if("ID" %in% names(M)) {
  keywords_id <- unlist(strsplit(M$ID[!is.na(M$ID) & M$ID != ""], ";"))
  keywords_id <- trimws(tolower(keywords_id))
  
  keywords_id_freq <- as.data.frame(table(keywords_id))
  names(keywords_id_freq) <- c("Keyword", "Occurrences")
  
  keywords_id_freq <- keywords_id_freq %>%
    arrange(desc(Occurrences)) %>%
    mutate(
      Rank = row_number(),
      Percentage = round(100 * Occurrences / nrow(M), 2)
    ) %>%
    head(50)
  
  write.csv(keywords_id_freq, "04_Results/13_Keywords_Plus.csv", row.names = FALSE)
  cat("   ✓ Top 50 keywords plus identified\n")
}

cat("\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

cat("8. Generating summary statistics...\n")

summary_stats <- data.frame(
  Metric = c(
    "Total Documents",
    "Timespan",
    "Average Document Age (years)",
    "Sources",
    "Authors",
    "Average Authors per Document",
    "Single-Authored Documents (%)",
    "Average Citations per Document",
    "Most Productive Year",
    "Most Productive Source",
    "Most Productive Author"
  ),
  Value = c(
    nrow(M),
    paste(min(M$PY, na.rm = TRUE), max(M$PY, na.rm = TRUE), sep = "-"),
    round(2024 - mean(M$PY, na.rm = TRUE), 2),
    length(unique(M$SO)),
    n_authors,
    round(n_appearances / nrow(M), 2),
    round(100 * single_authored / nrow(M), 1),
    round(mean(M$TC, na.rm = TRUE), 2),
    annual_production$PY[which.max(annual_production$Articles)],
    source_analysis$SO[1],
    author_freq$Author[1]
  )
)

print(summary_stats)
write.csv(summary_stats, "04_Results/00_Summary_Statistics.csv", row.names = FALSE)
cat("   ✓ Summary statistics saved\n\n")

# ============================================================================
# DESCRIPTIVE ANALYSIS COMPLETE
# ============================================================================

cat("=== DESCRIPTIVE ANALYSIS COMPLETE ===\n\n")
cat("Generated files:\n")
cat("  • 01_Main_Information.csv\n")
cat("  • 02_Annual_Scientific_Production.csv\n")
cat("  • 03_Most_Relevant_Sources.csv\n")
cat("  • 05_Most_Relevant_Authors.csv\n")
cat("  • 08_Most_Cited_Documents.csv\n")
cat("  • 12_Authors_Keywords.csv\n")
cat("  • 13_Keywords_Plus.csv\n")
cat("  • 00_Summary_Statistics.csv\n")
cat("  • Figures/annual_production.png\n")

cat("\nNext step: Run 06_thematic_analysis.R\n")
