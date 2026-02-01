# ============================================================================
# STBM ANALYSIS - STEP 03: DATA MERGING
# ============================================================================
# Purpose: Merge datasets from multiple databases
# Prerequisites: Imported data from step 02
# ============================================================================

# Load required libraries
library(bibliometrix)
library(dplyr)

cat("=== STBM DATA MERGING ===\n\n")

# ============================================================================
# LOAD IMPORTED DATA
# ============================================================================

cat("1. Loading imported datasets...\n")

load("02_Processed_Data/all_imported_data.RData")

# Count records
n_wos <- ifelse(is.null(wos_data), 0, nrow(wos_data))
n_scopus <- ifelse(is.null(scopus_data), 0, nrow(scopus_data))
n_openalex <- ifelse(is.null(openalex_data), 0, nrow(openalex_data))

cat("   ✓ WoS:", n_wos, "records\n")
cat("   ✓ Scopus:", n_scopus, "records\n")
cat("   ✓ OpenAlex:", n_openalex, "records\n")
cat("   Total before merging:", n_wos + n_scopus + n_openalex, "\n")

# ============================================================================
# MERGE DATABASES USING BIBLIOMETRIX
# ============================================================================

cat("\n2. Merging databases with automatic deduplication...\n")

# Create list of non-null datasets
datasets_to_merge <- list()
if(!is.null(wos_data)) datasets_to_merge[[length(datasets_to_merge) + 1]] <- wos_data
if(!is.null(scopus_data)) datasets_to_merge[[length(datasets_to_merge) + 1]] <- scopus_data
if(!is.null(openalex_data)) datasets_to_merge[[length(datasets_to_merge) + 1]] <- openalex_data

if(length(datasets_to_merge) < 2) {
  cat("   ✗ Need at least 2 datasets to merge\n")
  stop("Insufficient datasets for merging. Please import data from multiple sources.")
}

# Merge using bibliometrix function
merged_data <- do.call(mergeDbSources, c(datasets_to_merge, list(remove.duplicated = TRUE)))

cat("   ✓ Automatic merging complete\n")
cat("   Records after automatic deduplication:", nrow(merged_data), "\n")
cat("   Duplicates removed:", 
    (n_wos + n_scopus + n_openalex) - nrow(merged_data), "\n")

# ============================================================================
# CALCULATE DEDUPLICATION STATISTICS
# ============================================================================

cat("\n3. Calculating deduplication statistics...\n")

dedup_stats <- data.frame(
  Database = c("Web of Science", "Scopus", "OpenAlex", 
               "Total Retrieved", "After Auto-Dedup", "Duplicates Removed"),
  Records = c(n_wos, n_scopus, n_openalex,
              n_wos + n_scopus + n_openalex,
              nrow(merged_data),
              (n_wos + n_scopus + n_openalex) - nrow(merged_data)),
  Percentage = c(
    ifelse(n_wos > 0, round(100 * n_wos / (n_wos + n_scopus + n_openalex), 1), 0),
    ifelse(n_scopus > 0, round(100 * n_scopus / (n_wos + n_scopus + n_openalex), 1), 0),
    ifelse(n_openalex > 0, round(100 * n_openalex / (n_wos + n_scopus + n_openalex), 1), 0),
    100.0,
    round(100 * nrow(merged_data) / (n_wos + n_scopus + n_openalex), 1),
    round(100 * ((n_wos + n_scopus + n_openalex) - nrow(merged_data)) / (n_wos + n_scopus + n_openalex), 1)
  )
)

print(dedup_stats)

# Save statistics
write.csv(dedup_stats, "02_Processed_Data/deduplication_stats.csv", row.names = FALSE)

# ============================================================================
# SAVE MERGED DATA
# ============================================================================

cat("\n4. Saving merged dataset...\n")

# Save in multiple formats
save(merged_data, file = "02_Processed_Data/merged_data.RData")
write.csv(merged_data, "02_Processed_Data/merged_data.csv", row.names = FALSE)

cat("   ✓ Saved as RData: 02_Processed_Data/merged_data.RData\n")
cat("   ✓ Saved as CSV: 02_Processed_Data/merged_data.csv\n")

# ============================================================================
# MERGING SUMMARY
# ============================================================================

cat("\n=== MERGING SUMMARY ===\n\n")
cat("Initial records:", n_wos + n_scopus + n_openalex, "\n")
cat("After automatic deduplication:", nrow(merged_data), "\n")
cat("Reduction:", round(100 * ((n_wos + n_scopus + n_openalex) - nrow(merged_data)) / (n_wos + n_scopus + n_openalex), 1), "%\n")

# Check data quality
cat("\nData quality check:\n")
cat("  Records with title:", sum(!is.na(merged_data$TI) & merged_data$TI != ""), "\n")
cat("  Records with authors:", sum(!is.na(merged_data$AU) & merged_data$AU != ""), "\n")
cat("  Records with year:", sum(!is.na(merged_data$PY)), "\n")
cat("  Records with DOI:", sum(!is.na(merged_data$DI) & merged_data$DI != ""), "\n")

cat("\n=== MERGING COMPLETE ===\n")
cat("Next step: Run 04_advanced_deduplication.R for manual verification\n")
