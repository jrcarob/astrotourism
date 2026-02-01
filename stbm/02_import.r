# ============================================================================
# STBM ANALYSIS - STEP 02: DATA IMPORT
# ============================================================================
# Purpose: Import data from Web of Science, Scopus, and OpenAlex
# Prerequisites: Raw data files in 01_Raw_Data/ folder
# ============================================================================

# Load required libraries
library(bibliometrix)
library(dplyr)

# Set working directory (adjust if needed)
# setwd("~/STBM_Astrotourism_Analysis")

cat("=== STBM DATA IMPORT ===\n\n")

# ============================================================================
# IMPORT WEB OF SCIENCE DATA
# ============================================================================

cat("1. Importing Web of Science data...\n")

# List all WoS files in Raw_Data folder
wos_files <- list.files("01_Raw_Data", pattern = "WoS.*\\.txt$", full.names = TRUE)

if(length(wos_files) == 0) {
  cat("   ✗ No WoS files found in 01_Raw_Data/\n")
  cat("   Expected file pattern: WoS*.txt\n")
  wos_data <- NULL
} else {
  cat("   Found", length(wos_files), "WoS file(s)\n")
  
  # Import WoS data
  wos_data <- convert2df(
    file = wos_files,
    dbsource = "wos",
    format = "plaintext"
  )
  
  cat("   ✓ WoS records imported:", nrow(wos_data), "\n")
  cat("   ✓ WoS columns:", ncol(wos_data), "\n")
  
  # Preview
  cat("   Preview of first 3 records:\n")
  print(head(wos_data[, c("TI", "AU", "PY", "SO")], 3))
}

# ============================================================================
# IMPORT SCOPUS DATA
# ============================================================================

cat("\n2. Importing Scopus data...\n")

# List Scopus files
scopus_files <- list.files("01_Raw_Data", pattern = "Scopus.*\\.csv$", full.names = TRUE)

if(length(scopus_files) == 0) {
  cat("   ✗ No Scopus files found in 01_Raw_Data/\n")
  cat("   Expected file pattern: Scopus*.csv\n")
  scopus_data <- NULL
} else {
  cat("   Found", length(scopus_files), "Scopus file(s)\n")
  
  # Import Scopus data
  scopus_data <- convert2df(
    file = scopus_files,
    dbsource = "scopus",
    format = "csv"
  )
  
  cat("   ✓ Scopus records imported:", nrow(scopus_data), "\n")
  cat("   ✓ Scopus columns:", ncol(scopus_data), "\n")
  
  # Preview
  cat("   Preview of first 3 records:\n")
  print(head(scopus_data[, c("TI", "AU", "PY", "SO")], 3))
}

# ============================================================================
# IMPORT OPENALEX DATA
# ============================================================================

cat("\n3. Importing OpenAlex data...\n")

# List OpenAlex files
openalex_files <- list.files("01_Raw_Data", pattern = "OpenAlex.*\\.csv$", full.names = TRUE)

if(length(openalex_files) == 0) {
  cat("   ✗ No OpenAlex files found in 01_Raw_Data/\n")
  cat("   Expected file pattern: OpenAlex*.csv\n")
  openalex_data <- NULL
} else {
  cat("   Found", length(openalex_files), "OpenAlex file(s)\n")
  
  # Import OpenAlex data (already in CSV format)
  openalex_raw <- read.csv(openalex_files[1], stringsAsFactors = FALSE)
  
  cat("   ✓ OpenAlex records imported:", nrow(openalex_raw), "\n")
  
  # Convert OpenAlex to bibliometrix format
  # Note: Field mapping may vary based on OpenAlex export format
  # Adjust column names as needed
  
  openalex_data <- data.frame(
    TI = openalex_raw$title,
    AU = openalex_raw$author_names,
    PY = as.numeric(substr(openalex_raw$publication_date, 1, 4)),
    SO = openalex_raw$source,
    DI = openalex_raw$doi,
    AB = openalex_raw$abstract,
    TC = openalex_raw$cited_by_count,
    stringsAsFactors = FALSE
  )
  
  cat("   ✓ OpenAlex converted to standard format\n")
  cat("   Preview of first 3 records:\n")
  print(head(openalex_data[, c("TI", "AU", "PY", "SO")], 3))
}

# ============================================================================
# ADD SOURCE TRACKING
# ============================================================================

cat("\n4. Adding database source tracking...\n")

if(!is.null(wos_data)) {
  wos_data$DB_SOURCE <- "WoS"
  cat("   ✓ Tagged", nrow(wos_data), "WoS records\n")
}

if(!is.null(scopus_data)) {
  scopus_data$DB_SOURCE <- "Scopus"
  cat("   ✓ Tagged", nrow(scopus_data), "Scopus records\n")
}

if(!is.null(openalex_data)) {
  openalex_data$DB_SOURCE <- "OpenAlex"
  cat("   ✓ Tagged", nrow(openalex_data), "OpenAlex records\n")
}

# ============================================================================
# SAVE IMPORTED DATA
# ============================================================================

cat("\n5. Saving imported datasets...\n")

# Save individual datasets
if(!is.null(wos_data)) {
  save(wos_data, file = "02_Processed_Data/wos_imported.RData")
  write.csv(wos_data, "02_Processed_Data/wos_imported.csv", row.names = FALSE)
  cat("   ✓ Saved WoS data\n")
}

if(!is.null(scopus_data)) {
  save(scopus_data, file = "02_Processed_Data/scopus_imported.RData")
  write.csv(scopus_data, "02_Processed_Data/scopus_imported.csv", row.names = FALSE)
  cat("   ✓ Saved Scopus data\n")
}

if(!is.null(openalex_data)) {
  save(openalex_data, file = "02_Processed_Data/openalex_imported.RData")
  write.csv(openalex_data, "02_Processed_Data/openalex_imported.csv", row.names = FALSE)
  cat("   ✓ Saved OpenAlex data\n")
}

# Save all together
save(wos_data, scopus_data, openalex_data, 
     file = "02_Processed_Data/all_imported_data.RData")
cat("   ✓ Saved combined workspace\n")

# ============================================================================
# IMPORT SUMMARY
# ============================================================================

cat("\n=== IMPORT SUMMARY ===\n\n")

total_records <- 0
if(!is.null(wos_data)) total_records <- total_records + nrow(wos_data)
if(!is.null(scopus_data)) total_records <- total_records + nrow(scopus_data)
if(!is.null(openalex_data)) total_records <- total_records + nrow(openalex_data)

summary_df <- data.frame(
  Database = c("Web of Science", "Scopus", "OpenAlex", "TOTAL (before deduplication)"),
  Records = c(
    ifelse(is.null(wos_data), 0, nrow(wos_data)),
    ifelse(is.null(scopus_data), 0, nrow(scopus_data)),
    ifelse(is.null(openalex_data), 0, nrow(openalex_data)),
    total_records
  ),
  Status = c(
    ifelse(is.null(wos_data), "Not imported", "✓ Imported"),
    ifelse(is.null(scopus_data), "Not imported", "✓ Imported"),
    ifelse(is.null(openalex_data), "Not imported", "✓ Imported"),
    ""
  )
)

print(summary_df)

cat("\nExpected overlap: 40-60% (duplicates across databases)\n")
cat("Expected unique records after merging: ~", round(total_records * 0.55), "-", round(total_records * 0.70), "\n")

# Save summary
write.csv(summary_df, "02_Processed_Data/import_summary.csv", row.names = FALSE)

cat("\n=== IMPORT COMPLETE ===\n")
cat("Next step: Run 03_data_merging.R\n")
