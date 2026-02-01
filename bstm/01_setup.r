# ============================================================================
# STBM ANALYSIS - STEP 01: PROJECT SETUP
# ============================================================================
# Purpose: Create organized folder structure for STBM analysis
# Run this script ONCE at the beginning
# ============================================================================

# Set your project root directory
# MODIFY THIS PATH TO YOUR DESIRED LOCATION
project_root <- "~/STBM_Astrotourism_Analysis"

# Create project root if it doesn't exist
if(!dir.exists(project_root)) {
  dir.create(project_root, recursive = TRUE)
  cat("✓ Created project root:", project_root, "\n")
} else {
  cat("Project root already exists:", project_root, "\n")
}

# Set as working directory
setwd(project_root)
cat("Working directory set to:", getwd(), "\n\n")

# Create folder structure
folders <- c(
  "01_Raw_Data",
  "02_Processed_Data",
  "03_Analysis",
  "04_Results",
  "04_Results/Figures",
  "04_Results/Tables",
  "04_Results/Networks",
  "Scripts",
  "Documentation"
)

cat("Creating folder structure...\n")
for(folder in folders) {
  if(!dir.exists(folder)) {
    dir.create(folder, recursive = TRUE)
    cat("  ✓ Created:", folder, "\n")
  } else {
    cat("  - Already exists:", folder, "\n")
  }
}

# Create README file
readme_content <- paste0(
  "# STBM Analysis Project\n\n",
  "Research Topic: [Add your topic here]\n",
  "Analyst: [Your name]\n",
  "Date Started: ", Sys.Date(), "\n\n",
  "## Folder Structure\n\n",
  "- **01_Raw_Data/**: Original exports from databases (WoS, Scopus, OpenAlex)\n",
  "- **02_Processed_Data/**: Merged and cleaned datasets\n",
  "- **03_Analysis/**: Intermediate analysis outputs\n",
  "- **04_Results/**: Final results, figures, tables\n",
  "- **Scripts/**: All R scripts for analysis\n",
  "- **Documentation/**: Search protocols, notes\n\n",
  "## Analysis Steps\n\n",
  "1. Data Retrieval (Manual - from databases)\n",
  "2. Data Import (Script 02)\n",
  "3. Data Merging (Script 03)\n",
  "4. Deduplication (Script 04)\n",
  "5. Descriptive Analysis (Script 05)\n",
  "6. Thematic Analysis (Script 06)\n",
  "7. Semantic Analysis (Script 07)\n",
  "8. Network Analysis (Script 08)\n",
  "9. Synthesis (Script 09)\n"
)

writeLines(readme_content, "README.md")
cat("\n✓ Created README.md\n")

# Create search documentation template
search_doc_content <- paste0(
  "BIBLIOMETRIC SEARCH DOCUMENTATION\n",
  "================================\n\n",
  "Research Topic: [e.g., Astrotourism]\n",
  "Researcher: [Name]\n",
  "Date of Search: [YYYY-MM-DD]\n\n",
  "WEB OF SCIENCE CORE COLLECTION\n",
  "------------------------------\n",
  "Date Searched: [YYYY-MM-DD]\n",
  "Search Query: \n",
  "  TS=(\"keyword1\" OR \"keyword2\")\n",
  "  AND\n",
  "  TS=(topic OR related*)\n\n",
  "Timespan: YYYY-YYYY\n",
  "Indexes: SCI-EXPANDED, SSCI, A&HCI, ESCI\n",
  "Document Types: Articles, Reviews, Book Chapters\n",
  "Results: [Number] documents\n",
  "Export Files: \n",
  "  - WoS_Records.txt\n\n",
  "SCOPUS\n",
  "------\n",
  "Date Searched: [YYYY-MM-DD]\n",
  "Search Query:\n",
  "  TITLE-ABS-KEY(\"keyword1\" OR \"keyword2\")\n\n",
  "Results: [Number] documents\n",
  "Export Files:\n",
  "  - Scopus_Records.csv\n\n",
  "OPENALEX\n",
  "--------\n",
  "Date Searched: [YYYY-MM-DD]\n",
  "Search Method: API\n",
  "Results: [Number] documents\n",
  "Export Files:\n",
  "  - OpenAlex_Records.csv\n\n",
  "NOTES\n",
  "-----\n",
  "[Add any observations or decisions made during search]\n"
)

writeLines(search_doc_content, "Documentation/Search_Protocol_Template.txt")
cat("✓ Created search documentation template\n")

# Print summary
cat("\n=== PROJECT SETUP COMPLETE ===\n\n")
cat("Project location:", getwd(), "\n")
cat("Folders created:", length(folders), "\n")
cat("\nNext steps:\n")
cat("1. Retrieve data from Web of Science, Scopus, and OpenAlex\n")
cat("2. Place raw data files in 01_Raw_Data/ folder\n")
cat("3. Document your search in Documentation/Search_Protocol_Template.txt\n")
cat("4. Run 02_data_import.R\n")
