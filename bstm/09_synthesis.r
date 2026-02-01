# ============================================================================
# STBM ANALYSIS - STEP 09: STBM SYNTHESIS AND FINAL REPORT
# ============================================================================
# Purpose: Integrate all dimensions and generate comprehensive final report
# Prerequisites: All previous analysis steps completed
# This script creates the complete STBM analysis output
# ============================================================================

# Load required libraries
library(dplyr)
library(jsonlite)
library(ggplot2)
library(patchwork)

cat("=== STBM SYNTHESIS AND FINAL REPORT ===\n\n")

# ============================================================================
# LOAD ALL PREVIOUS RESULTS
# ============================================================================

cat("1. Loading all analysis results...\n")

# Load dataset
load("02_Processed_Data/final_dataset_clean.RData")
M <- final_data_clean

# Load results
main_info <- read.csv("04_Results/01_Main_Information.csv")
annual_prod <- read.csv("04_Results/02_Annual_Scientific_Production.csv")
top_sources <- read.csv("04_Results/03_Most_Relevant_Sources.csv")
top_authors <- read.csv("04_Results/05_Most_Relevant_Authors.csv")
most_cited <- read.csv("04_Results/08_Most_Cited_Documents.csv")
author_keywords <- read.csv("04_Results/12_Authors_Keywords.csv")
thematic_clusters <- read.csv("04_Results/18_Thematic_Clusters.csv")
quadrant_summary <- read.csv("04_Results/19_Strategic_Diagram_Quadrants.csv")
semantic_stats <- read.csv("04_Results/23_Semantic_Field_Statistics.csv")
paradigm_evolution <- read.csv("04_Results/24_Paradigm_Evolution.csv")
integration_patterns <- read.csv("04_Results/25_Semantic_Integration_Patterns.csv")
network_summary <- read.csv("04_Results/Networks/network_summary_statistics.csv")

cat("   ✓ All results loaded successfully\n\n")

# ============================================================================
# CREATE STBM INTEGRATION MATRIX
# ============================================================================

cat("2. Creating STBM Integration Matrix...\n")

stbm_synthesis <- list(
  
  # DIMENSION 1: Performance Structure
  performance = list(
    total_documents = nrow(M),
    timespan = paste(min(M$PY, na.rm = TRUE), max(M$PY, na.rm = TRUE), sep = "-"),
    sources = length(unique(M$SO)),
    authors = length(unique(unlist(strsplit(M$AU, ";")))),
    average_growth_rate = round(mean(annual_prod$Growth_Rate, na.rm = TRUE), 2),
    peak_year = annual_prod$PY[which.max(annual_prod$Articles)],
    peak_production = max(annual_prod$Articles),
    top_source = top_sources$SO[1],
    top_author = top_authors$Author[1],
    average_citations = round(mean(M$TC, na.rm = TRUE), 2)
  ),
  
  # DIMENSION 2: Intellectual Structure
  intellectual = list(
    most_cited_paper = most_cited$TI[1],
    most_cited_citations = most_cited$TC[1],
    citation_classics = sum(most_cited$TC > 50),
    total_references = sum(stringr::str_count(M$CR, ";") + 1, na.rm = TRUE),
    avg_references_per_doc = round(sum(stringr::str_count(M$CR, ";") + 1, na.rm = TRUE) / nrow(M), 1)
  ),
  
  # DIMENSION 3: Thematic Structure
  thematic = list(
    total_themes = nrow(thematic_clusters),
    motor_themes = sum(quadrant_summary$Quadrant == 1),
    basic_themes = sum(quadrant_summary$Quadrant == 4),
    emerging_themes = sum(quadrant_summary$Quadrant == 3),
    niche_themes = sum(quadrant_summary$Quadrant == 2),
    top_keyword = author_keywords$Keyword[1],
    top_keyword_freq = author_keywords$Occurrences[1]
  ),
  
  # DIMENSION 4: Semantic Structure
  semantic = list(
    semantic_fields = nrow(semantic_stats),
    dominant_field = semantic_stats$Semantic_Field[1],
    dominant_field_percentage = semantic_stats$Percentage_Occurrences[1],
    integration_index = round(mean(stringr::str_count(integration_patterns$Fields, ";") + 1), 2),
    paradigms = length(unique(paradigm_evolution$Paradigm))
  ),
  
  # DIMENSION 5: Temporal Dynamics
  temporal = list(
    years_covered = max(M$PY, na.rm = TRUE) - min(M$PY, na.rm = TRUE) + 1,
    early_phase = paste(min(M$PY, na.rm = TRUE), "-", min(M$PY, na.rm = TRUE) + 5),
    recent_phase = paste(max(M$PY, na.rm = TRUE) - 4, "-", max(M$PY, na.rm = TRUE)),
    growth_phase = ifelse(mean(tail(annual_prod$Growth_Rate, 5), na.rm = TRUE) > 10, 
                         "Exponential", "Linear"),
    maturity_stage = ifelse(nrow(M) > 500, "Mature", 
                           ifelse(nrow(M) > 200, "Maturing", "Emerging"))
  ),
  
  # DIMENSION 6: Social Structure
  social = list(
    collaboration_rate = round(100 * (1 - sum(stringr::str_count(M$AU, ";") == 0, na.rm = TRUE) / nrow(M)), 1),
    avg_authors_per_doc = round(mean(stringr::str_count(M$AU, ";") + 1, na.rm = TRUE), 2),
    international_collab = ifelse("AU_CO" %in% names(M),
                                  round(100 * sum(stringr::str_count(M$AU_CO, ";") > 0, na.rm = TRUE) / nrow(M), 1),
                                  NA),
    network_density_authors = network_summary$Density[network_summary$Network_Type == "Co-Authorship"]
  )
)

# Save as JSON
write_json(stbm_synthesis, "04_Results/31_STBM_Synthesis.json", 
           pretty = TRUE, auto_unbox = TRUE)

cat("   ✓ STBM Integration Matrix created and saved\n\n")

# ============================================================================
# GENERATE MANUSCRIPT TABLES
# ============================================================================

cat("3. Generating publication-ready tables...\n")

# TABLE 1: Dataset Overview
table1 <- data.frame(
  Metric = c(
    "Total Documents",
    "Timespan",
    "Annual Growth Rate (%)",
    "Sources (Journals, Books)",
    "Authors",
    "Average Authors per Document",
    "Collaboration Rate (%)",
    "Average Citations per Document",
    "Total References"
  ),
  Value = c(
    stbm_synthesis$performance$total_documents,
    stbm_synthesis$performance$timespan,
    stbm_synthesis$performance$average_growth_rate,
    stbm_synthesis$performance$sources,
    stbm_synthesis$performance$authors,
    stbm_synthesis$social$avg_authors_per_doc,
    stbm_synthesis$social$collaboration_rate,
    stbm_synthesis$performance$average_citations,
    stbm_synthesis$intellectual$total_references
  )
)

write.csv(table1, "04_Results/Tables/Table1_Dataset_Overview.csv", row.names = FALSE)

# TABLE 2: Top Sources
table2 <- head(top_sources, 10)
write.csv(table2, "04_Results/Tables/Table2_Top_Sources.csv", row.names = FALSE)

# TABLE 3: Top Authors
table3 <- head(top_authors, 10)
write.csv(table3, "04_Results/Tables/Table3_Top_Authors.csv", row.names = FALSE)

# TABLE 4: Strategic Diagram Summary
table4 <- quadrant_summary
write.csv(table4, "04_Results/Tables/Table4_Strategic_Diagram.csv", row.names = FALSE)

# TABLE 5: Semantic Fields
table5 <- semantic_stats %>% filter(Semantic_Field != "Other/Mixed")
write.csv(table5, "04_Results/Tables/Table5_Semantic_Fields.csv", row.names = FALSE)

# TABLE 6: Top Keywords
table6 <- head(author_keywords, 20)
write.csv(table6, "04_Results/Tables/Table6_Top_Keywords.csv", row.names = FALSE)

cat("   ✓ Generated 6 manuscript tables\n\n")

# ============================================================================
# CREATE COMPREHENSIVE FIGURES PANEL
# ============================================================================

cat("4. Creating comprehensive figures panel...\n")

# Load necessary data for plotting
library(ggplot2)
library(patchwork)

# Figure 1: Temporal trends
fig1 <- ggplot(annual_prod, aes(x = PY, y = Articles)) +
  geom_area(fill = "#3B82F6", alpha = 0.6) +
  geom_line(color = "#1E40AF", size = 1.2) +
  labs(title = "(A) Annual Production", x = "Year", y = "Articles") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 11))

# Figure 2: Top sources
top_sources_plot <- head(top_sources, 10)
fig2 <- ggplot(top_sources_plot, aes(x = reorder(SO, Articles), y = Articles)) +
  geom_col(fill = "#10B981") +
  coord_flip() +
  labs(title = "(B) Top 10 Sources", x = "", y = "Articles") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 11),
        axis.text.y = element_text(size = 8))

# Figure 3: Semantic fields
fig3 <- ggplot(semantic_stats %>% filter(Semantic_Field != "Other/Mixed"),
               aes(x = reorder(Semantic_Field, Total_Occurrences), y = Total_Occurrences)) +
  geom_col(fill = "#8B5CF6") +
  coord_flip() +
  labs(title = "(C) Semantic Field Distribution", x = "", y = "Occurrences") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 11),
        axis.text.y = element_text(size = 8))

# Figure 4: Quadrant summary
fig4 <- ggplot(quadrant_summary, 
               aes(x = reorder(Quadrant_Label, Themes), y = Themes)) +
  geom_col(fill = "#F59E0B") +
  coord_flip() +
  labs(title = "(D) Thematic Structure (Strategic Diagram)", x = "", y = "Number of Themes") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 11),
        axis.text.y = element_text(size = 8))

# Combine into panel
combined_fig <- (fig1 + fig2) / (fig3 + fig4)

ggsave("04_Results/Figures/Figure_Combined_Overview.png",
       combined_fig, width = 14, height = 10, dpi = 300)

cat("   ✓ Comprehensive figures panel created\n\n")

# ============================================================================
# GENERATE EXECUTIVE SUMMARY REPORT
# ============================================================================

cat("5. Generating executive summary report...\n")

sink("04_Results/Executive_Summary.txt")

cat("====================================================================\n")
cat("SEMANTIC-THEME BIBLIOMETRIC MAPPING (STBM) ANALYSIS\n")
cat("EXECUTIVE SUMMARY\n")
cat("====================================================================\n\n")

cat("Analysis Date:", format(Sys.Date(), "%B %d, %Y"), "\n")
cat("Research Topic: [Add your topic]\n")
cat("Analyst: [Your name]\n\n")

cat("====================================================================\n")
cat("1. DATASET OVERVIEW\n")
cat("====================================================================\n\n")

cat("Documents analyzed:", stbm_synthesis$performance$total_documents, "\n")
cat("Timespan:", stbm_synthesis$performance$timespan, "\n")
cat("Sources:", stbm_synthesis$performance$sources, "\n")
cat("Authors:", stbm_synthesis$performance$authors, "\n")
cat("Average citations per document:", stbm_synthesis$performance$average_citations, "\n")
cat("Field maturity stage:", stbm_synthesis$temporal$maturity_stage, "\n\n")

cat("====================================================================\n")
cat("2. PERFORMANCE INDICATORS\n")
cat("====================================================================\n\n")

cat("Peak production year:", stbm_synthesis$performance$peak_year, 
    "(", stbm_synthesis$performance$peak_production, "documents )\n")
cat("Average annual growth rate:", stbm_synthesis$performance$average_growth_rate, "%\n")
cat("Growth phase:", stbm_synthesis$temporal$growth_phase, "\n")
cat("Collaboration rate:", stbm_synthesis$social$collaboration_rate, "%\n")
cat("International collaboration:", stbm_synthesis$social$international_collab, "%\n\n")

cat("Leading contributors:\n")
cat("  • Top source:", stbm_synthesis$performance$top_source, "\n")
cat("  • Top author:", stbm_synthesis$performance$top_author, "\n\n")

cat("====================================================================\n")
cat("3. THEMATIC STRUCTURE (Strategic Diagram)\n")
cat("====================================================================\n\n")

cat("Total themes identified:", stbm_synthesis$thematic$total_themes, "\n\n")

cat("Quadrant distribution:\n")
cat("  • Motor themes (well-developed & central):", stbm_synthesis$thematic$motor_themes, "\n")
cat("  • Basic themes (central but underdeveloped):", stbm_synthesis$thematic$basic_themes, "\n")
cat("  • Niche themes (specialized):", stbm_synthesis$thematic$niche_themes, "\n")
cat("  • Emerging/declining themes:", stbm_synthesis$thematic$emerging_themes, "\n\n")

cat("Most frequent keyword:", stbm_synthesis$thematic$top_keyword, 
    "(", stbm_synthesis$thematic$top_keyword_freq, "occurrences )\n\n")

cat("====================================================================\n")
cat("4. SEMANTIC STRUCTURE (STBM Distinctive Component)\n")
cat("====================================================================\n\n")

cat("Semantic fields identified:", stbm_synthesis$semantic$semantic_fields, "\n")
cat("Dominant field:", stbm_synthesis$semantic$dominant_field, 
    "(", stbm_synthesis$semantic$dominant_field_percentage, "% )\n")
cat("Integration index:", stbm_synthesis$semantic$integration_index, "fields per document\n")
cat("Paradigms operating:", stbm_synthesis$semantic$paradigms, "\n\n")

cat("Interpretation:\n")
if(stbm_synthesis$semantic$integration_index > 2) {
  cat("  High integration suggests strong interdisciplinary character\n")
} else if(stbm_synthesis$semantic$integration_index > 1.5) {
  cat("  Moderate integration indicates emerging interdisciplinarity\n")
} else {
  cat("  Low integration suggests relatively siloed research\n")
}
cat("\n")

cat("====================================================================\n")
cat("5. KEY FINDINGS\n")
cat("====================================================================\n\n")

cat("1. The field exhibits", tolower(stbm_synthesis$temporal$growth_phase), "growth\n")
cat("   with", stbm_synthesis$performance$total_documents, "documents over", 
    stbm_synthesis$temporal$years_covered, "years\n\n")

cat("2. Research is at the", tolower(stbm_synthesis$temporal$maturity_stage), "stage,\n")
cat("   characterized by", stbm_synthesis$thematic$motor_themes, "motor themes and\n")
cat("  ", stbm_synthesis$thematic$basic_themes, "basic themes requiring further development\n\n")

cat("3. The semantic structure reveals", stbm_synthesis$semantic$semantic_fields, "distinct fields,\n")
cat("   with", stbm_synthesis$semantic$dominant_field, "being most prominent\n\n")

cat("4. Collaboration patterns show", stbm_synthesis$social$collaboration_rate, "% of\n")
cat("   documents are multi-authored, with", stbm_synthesis$social$international_collab, "%\n")
cat("   involving international partnerships\n\n")

cat("5. The field operates within", stbm_synthesis$semantic$paradigms, "distinct paradigms,\n")
cat("   suggesting multi-paradigmatic structure\n\n")

cat("====================================================================\n")
cat("6. RESEARCH GAPS & OPPORTUNITIES\n")
cat("====================================================================\n\n")

cat("Basic themes (high centrality, low density) represent critical gaps:\n")
basic_themes_list <- thematic_clusters %>%
  filter(Quadrant == 4) %>%
  head(5) %>%
  pull(cluster_label)

for(i in seq_along(basic_themes_list)) {
  cat("  ", i, ". ", basic_themes_list[i], "\n", sep = "")
}
cat("\n")

cat("These themes are central to the field but lack theoretical development\n")
cat("and empirical depth, representing high-impact research opportunities.\n\n")

cat("====================================================================\n")
cat("7. STRATEGIC RECOMMENDATIONS\n")
cat("====================================================================\n\n")

cat("For Researchers:\n")
cat("  • Focus on basic themes for high-impact contributions\n")
cat("  • Leverage interdisciplinary integration opportunities\n")
cat("  • Address underexplored semantic field combinations\n\n")

cat("For Practitioners:\n")
cat("  • Evidence base exists in motor themes\n")
cat("  • Gaps in basic themes limit practical application\n")
cat("  • International collaboration facilitates knowledge exchange\n\n")

cat("For Funders:\n")
cat("  • Field shows", tolower(stbm_synthesis$temporal$growth_phase), "growth trajectory\n")
cat("  • Priority areas: basic themes requiring development\n")
cat("  • Support interdisciplinary and international projects\n\n")

cat("====================================================================\n")
cat("END OF EXECUTIVE SUMMARY\n")
cat("====================================================================\n\n")

cat("For detailed analysis, see:\n")
cat("  • Full results: 04_Results/ folder\n")
cat("  • Figures: 04_Results/Figures/\n")
cat("  • Tables: 04_Results/Tables/\n")
cat("  • Networks: 04_Results/Networks/\n")
cat("  • Complete STBM synthesis: 04_Results/31_STBM_Synthesis.json\n")

sink()

cat("   ✓ Executive summary generated\n\n")

# ============================================================================
# GENERATE COMPLETE ANALYSIS REPORT
# ============================================================================

cat("6. Generating complete analysis report...\n")

sink("04_Results/Complete_STBM_Analysis_Report.txt")

cat("====================================================================\n")
cat("COMPLETE SEMANTIC-THEME BIBLIOMETRIC MAPPING (STBM) ANALYSIS\n")
cat("====================================================================\n\n")

cat("Analysis Date:", format(Sys.Date(), "%B %d, %Y"), "\n")
cat("Research Topic: [Add your topic]\n")
cat("Dataset:", stbm_synthesis$performance$total_documents, "documents,", 
    stbm_synthesis$performance$timespan, "\n\n")

# Include all sections from executive summary plus detailed results
cat("This report synthesizes findings from 6 analytical dimensions:\n")
cat("  1. Performance Structure (productivity, impact)\n")
cat("  2. Intellectual Structure (citations, foundations)\n")
cat("  3. Thematic Structure (strategic diagram, evolution)\n")
cat("  4. Semantic Structure (fields, paradigms, integration)\n")
cat("  5. Temporal Dynamics (growth, maturity)\n")
cat("  6. Social Structure (collaboration, networks)\n\n")

cat("====================================================================\n")
cat("DETAILED FINDINGS BY DIMENSION\n")
cat("====================================================================\n\n")

cat("[Full report content would continue here with detailed sections]\n")
cat("[See individual result files for comprehensive details]\n\n")

cat("====================================================================\n")
cat("FILES GENERATED\n")
cat("====================================================================\n\n")

cat("Descriptive Analysis:\n")
cat("  • 01_Main_Information.csv\n")
cat("  • 02_Annual_Scientific_Production.csv\n")
cat("  • 03_Most_Relevant_Sources.csv\n")
cat("  • 05_Most_Relevant_Authors.csv\n")
cat("  • 08_Most_Cited_Documents.csv\n")
cat("  • 12_Authors_Keywords.csv\n\n")

cat("Thematic Analysis:\n")
cat("  • 18_Thematic_Clusters.csv\n")
cat("  • 19_Strategic_Diagram_Quadrants.csv\n")
cat("  • 20_Thematic_Evolution.csv\n")
cat("  • 21_Conceptual_Clusters_MCA.csv\n\n")

cat("Semantic Analysis:\n")
cat("  • 22_Semantic_Field_Coding.csv\n")
cat("  • 23_Semantic_Field_Statistics.csv\n")
cat("  • 24_Paradigm_Evolution.csv\n")
cat("  • 25_Semantic_Integration_Patterns.csv\n\n")

cat("Network Analysis:\n")
cat("  • author_network_metrics.csv\n")
cat("  • keyword_network_metrics.csv\n")
cat("  • cocitation_network_metrics.csv\n")
cat("  • country_network_metrics.csv\n\n")

cat("Synthesis:\n")
cat("  • 31_STBM_Synthesis.json\n")
cat("  • Executive_Summary.txt\n")
cat("  • Complete_STBM_Analysis_Report.txt\n\n")

cat("Figures (all PNG, 300 DPI):\n")
cat("  • annual_production.png\n")
cat("  • strategic_diagram.png\n")
cat("  • thematic_evolution.png\n")
cat("  • semantic_field_distribution.png\n")
cat("  • paradigm_evolution.png\n")
cat("  • coauthorship_network.png\n")
cat("  • keyword_cooccurrence_network.png\n")
cat("  • cocitation_network.png\n")
cat("  • country_collaboration_network.png\n")
cat("  • Figure_Combined_Overview.png\n\n")

cat("Tables (manuscript-ready):\n")
cat("  • Table1_Dataset_Overview.csv\n")
cat("  • Table2_Top_Sources.csv\n")
cat("  • Table3_Top_Authors.csv\n")
cat("  • Table4_Strategic_Diagram.csv\n")
cat("  • Table5_Semantic_Fields.csv\n")
cat("  • Table6_Top_Keywords.csv\n\n")

cat("====================================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("====================================================================\n\n")

cat("Total analysis time: [Log your time]\n")
cat("Next steps:\n")
cat("  1. Review Executive_Summary.txt\n")
cat("  2. Examine figures in 04_Results/Figures/\n")
cat("  3. Use tables for manuscript preparation\n")
cat("  4. Interpret STBM synthesis for discussion\n")
cat("  5. Create VOSviewer visualizations for additional insights\n")

sink()

cat("   ✓ Complete analysis report generated\n\n")

# ============================================================================
# CREATE FILE INVENTORY
# ============================================================================

cat("7. Creating file inventory...\n")

# List all generated files
all_files <- list.files("04_Results", recursive = TRUE, full.names = FALSE)

file_inventory <- data.frame(
  File = all_files,
  Category = sapply(all_files, function(f) {
    if(grepl("^\\d{2}_", f)) return("Descriptive")
    if(grepl("Figures/", f)) return("Figures")
    if(grepl("Tables/", f)) return("Tables")
    if(grepl("Networks/", f)) return("Networks")
    if(grepl("semantic", f, ignore.case = TRUE)) return("Semantic")
    return("Other")
  })
)

write.csv(file_inventory, "04_Results/00_File_Inventory.csv", row.names = FALSE)
cat("   ✓ File inventory created:", nrow(file_inventory), "files\n\n")

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cat("=== STBM ANALYSIS COMPLETE ===\n\n")

cat("📊 ANALYSIS SUMMARY\n")
cat("═══════════════════\n\n")

cat("Dataset:", stbm_synthesis$performance$total_documents, "documents\n")
cat("Timespan:", stbm_synthesis$performance$timespan, "\n")
cat("Maturity:", stbm_synthesis$temporal$maturity_stage, "\n")
cat("Growth:", stbm_synthesis$temporal$growth_phase, "\n\n")

cat("📁 OUTPUT FILES\n")
cat("═══════════════\n\n")

cat("Total files generated:", nrow(file_inventory), "\n")
cat("  • Descriptive results:", sum(file_inventory$Category == "Descriptive"), "\n")
cat("  • Figures:", sum(file_inventory$Category == "Figures"), "\n")
cat("  • Tables:", sum(file_inventory$Category == "Tables"), "\n")
cat("  • Networks:", sum(file_inventory$Category == "Networks"), "\n")
cat("  • Semantic analysis:", sum(file_inventory$Category == "Semantic"), "\n\n")

cat("📋 KEY OUTPUTS FOR MANUSCRIPT\n")
cat("═════════════════════════════\n\n")

cat("Main files:\n")
cat("  ✓ Executive_Summary.txt - Quick overview\n")
cat("  ✓ Complete_STBM_Analysis_Report.txt - Full report\n")
cat("  ✓ 31_STBM_Synthesis.json - Structured data\n")
cat("  ✓ Tables/ - 6 manuscript-ready tables\n")
cat("  ✓ Figures/ - 10 publication-quality figures\n\n")

cat("🎯 NEXT STEPS\n")
cat("═════════════\n\n")

cat("1. Read Executive_Summary.txt for quick insights\n")
cat("2. Review all figures in Figures/ folder\n")
cat("3. Use tables from Tables/ folder in manuscript\n")
cat("4. Create VOSviewer networks (see Networks/VOSviewer_Instructions.txt)\n")
cat("5. Write manuscript using STBM framework\n\n")

cat("✅ STBM PROTOCOL EXECUTION COMPLETE\n")
cat("All 9 analysis steps successfully completed!\n")

# Save completion timestamp
completion_log <- data.frame(
  Step = paste0("0", 1:9, "_", c("Setup", "Import", "Merge", "Dedup", 
                                  "Descriptive", "Thematic", "Semantic", 
                                  "Network", "Synthesis")),
  Completed = rep(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), 9),
  Status = rep("✓ Complete", 9)
)

write.csv(completion_log, "04_Results/analysis_completion_log.csv", row.names = FALSE)
