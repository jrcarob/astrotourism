# ============================================================================
# STBM ANALYSIS - STEP 04: ADVANCED DEDUPLICATION
# ============================================================================
# Purpose: Advanced deduplication with manual verification
# Prerequisites: Merged data from step 03
# ============================================================================

# Load required libraries
library(dplyr)
library(stringr)

cat("=== ADVANCED DEDUPLICATION ===\n\n")

# ============================================================================
# LOAD MERGED DATA
# ============================================================================

cat("1. Loading merged dataset...\n")
load("02_Processed_Data/merged_data.RData")
cat("   ✓ Loaded:", nrow(merged_data), "records\n")

# ============================================================================
# ADVANCED DEDUPLICATION FUNCTION
# ============================================================================

cat("\n2. Performing advanced deduplication...\n")

advanced_deduplication <- function(df) {
  
  cat("   Creating matching keys...\n")
  
  # Create normalized matching keys
  df <- df %>%
    mutate(
      # Normalize titles (lowercase, remove punctuation)
      TI_clean = str_to_lower(TI) %>%
        str_replace_all("[[:punct:]]", "") %>%
        str_replace_all("\\s+", " ") %>%
        str_trim(),
      
      # Extract first author last name
      AU_first = ifelse(!is.na(AU) & AU != "",
                       str_extract(AU, "^[^;,]+"),
                       NA),
      
      # Normalize year
      PY_clean = as.character(PY),
      
      # Create composite matching key
      match_key = paste(TI_clean, AU_first, PY_clean, sep = "_")
    )
  
  cat("   Identifying duplicate groups...\n")
  
  # Identify duplicates
  df <- df %>%
    group_by(match_key) %>%
    mutate(
      duplicate_group = cur_group_id(),
      is_duplicate = n() > 1,
      duplicate_count = n(),
      record_rank = row_number()
    ) %>%
    ungroup()
  
  # Count duplicates
  n_duplicate_groups <- length(unique(df$duplicate_group[df$is_duplicate]))
  n_duplicate_records <- sum(df$is_duplicate)
  
  cat("   ✓ Duplicate groups found:", n_duplicate_groups, "\n")
  cat("   ✓ Total duplicate records:", n_duplicate_records, "\n")
  
  # For duplicates, keep the record with most complete information
  cat("   Selecting best record from each duplicate group...\n")
  
  df_dedup <- df %>%
    group_by(match_key) %>%
    arrange(
      desc(!is.na(DI) & DI != ""),           # Prefer records with DOI
      desc(!is.na(AB) & AB != ""),           # Then with abstract
      desc(!is.na(TC)),                       # Then with citation count
      desc(!is.na(CR) & CR != ""),           # Then with references
      desc(nchar(as.character(AU)))          # Then with more complete authors
    ) %>%
    slice(1) %>%
    ungroup()
  
  # Report results
  cat("\n   === Deduplication Results ===\n")
  cat("   Records before:", nrow(df), "\n")
  cat("   Duplicate groups:", n_duplicate_groups, "\n")
  cat("   Records after:", nrow(df_dedup), "\n")
  cat("   Additional duplicates removed:", nrow(df) - nrow(df_dedup), "\n")
  
  # Create duplicate report for manual inspection
  if(n_duplicate_groups > 0) {
    duplicates_report <- df %>%
      filter(is_duplicate) %>%
      arrange(duplicate_group, desc(record_rank)) %>%
      select(duplicate_group, TI, AU, PY, SO, DB_SOURCE, DI, TC, AB)
    
    write.csv(duplicates_report, 
              "02_Processed_Data/duplicates_detailed_report.csv", 
              row.names = FALSE)
    
    cat("   ✓ Duplicate report saved for manual inspection\n")
    cat("     File: 02_Processed_Data/duplicates_detailed_report.csv\n")
  }
  
  return(df_dedup)
}

# Apply advanced deduplication
final_data <- advanced_deduplication(merged_data)

# ============================================================================
# DATA QUALITY CHECK
# ============================================================================

cat("\n3. Performing data quality check...\n")

# Check for records missing critical fields
missing_critical <- final_data %>%
  filter(is.na(TI) | TI == "" | 
         is.na(AU) | AU == "" | 
         is.na(PY) | PY == "")

if(nrow(missing_critical) > 0) {
  cat("   ⚠ Found", nrow(missing_critical), "records missing critical fields\n")
  cat("   Creating report: 02_Processed_Data/records_missing_critical_fields.csv\n")
  
  write.csv(missing_critical %>% select(TI, AU, PY, SO, DB_SOURCE),
            "02_Processed_Data/records_missing_critical_fields.csv",
            row.names = FALSE)
  
  # Remove records missing critical fields
  final_data_clean <- final_data %>%
    filter(!is.na(TI) & TI != "",
           !is.na(AU) & AU != "",
           !is.na(PY) & PY != "")
  
  cat("   ✓ Removed", nrow(missing_critical), "incomplete records\n")
  cat("   Final clean dataset:", nrow(final_data_clean), "records\n")
  
} else {
  cat("   ✓ All records have critical fields\n")
  final_data_clean <- final_data
}

# ============================================================================
# COMPLETENESS REPORT
# ============================================================================

cat("\n4. Generating data completeness report...\n")

completeness <- data.frame(
  Field = c("Title (TI)", "Authors (AU)", "Year (PY)", "Source (SO)", 
            "DOI (DI)", "Abstract (AB)", "Keywords (DE)", "Keywords Plus (ID)",
            "Citations (TC)", "References (CR)"),
  Complete = c(
    sum(!is.na(final_data_clean$TI) & final_data_clean$TI != ""),
    sum(!is.na(final_data_clean$AU) & final_data_clean$AU != ""),
    sum(!is.na(final_data_clean$PY)),
    sum(!is.na(final_data_clean$SO) & final_data_clean$SO != ""),
    sum(!is.na(final_data_clean$DI) & final_data_clean$DI != ""),
    sum(!is.na(final_data_clean$AB) & final_data_clean$AB != ""),
    sum(!is.na(final_data_clean$DE) & final_data_clean$DE != ""),
    sum(!is.na(final_data_clean$ID) & final_data_clean$ID != ""),
    sum(!is.na(final_data_clean$TC)),
    sum(!is.na(final_data_clean$CR) & final_data_clean$CR != "")
  ),
  Missing = nrow(final_data_clean) - c(
    sum(!is.na(final_data_clean$TI) & final_data_clean$TI != ""),
    sum(!is.na(final_data_clean$AU) & final_data_clean$AU != ""),
    sum(!is.na(final_data_clean$PY)),
    sum(!is.na(final_data_clean$SO) & final_data_clean$SO != ""),
    sum(!is.na(final_data_clean$DI) & final_data_clean$DI != ""),
    sum(!is.na(final_data_clean$AB) & final_data_clean$AB != ""),
    sum(!is.na(final_data_clean$DE) & final_data_clean$DE != ""),
    sum(!is.na(final_data_clean$ID) & final_data_clean$ID != ""),
    sum(!is.na(final_data_clean$TC)),
    sum(!is.na(final_data_clean$CR) & final_data_clean$CR != "")
  )
)

completeness$Percent_Complete <- round(100 * completeness$Complete / nrow(final_data_clean), 1)

print(completeness)

write.csv(completeness, "02_Processed_Data/data_completeness_report.csv", row.names = FALSE)
cat("   ✓ Completeness report saved\n")

# ============================================================================
# SAVE FINAL CLEAN DATASET
# ============================================================================

cat("\n5. Saving final clean dataset...\n")

# Save in multiple formats
save(final_data_clean, file = "02_Processed_Data/final_dataset_clean.RData")
write.csv(final_data_clean, "02_Processed_Data/final_dataset_clean.csv", row.names = FALSE)

# Export for VOSviewer (tab-delimited format)
vosviewer_export <- final_data_clean %>%
  select(TI, AU, PY, SO, DI, AB, DE, ID, CR, TC) %>%
  mutate(AU = str_replace_all(AU, ";", "; "))

write.table(vosviewer_export, 
            "02_Processed_Data/for_vosviewer.txt",
            sep = "\t",
            row.names = FALSE,
            quote = FALSE,
            fileEncoding = "UTF-8")

cat("   ✓ Saved as RData: 02_Processed_Data/final_dataset_clean.RData\n")
cat("   ✓ Saved as CSV: 02_Processed_Data/final_dataset_clean.csv\n")
cat("   ✓ Saved for VOSviewer: 02_Processed_Data/for_vosviewer.txt\n")

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cat("\n=== DEDUPLICATION COMPLETE ===\n\n")
cat("Final dataset statistics:\n")
cat("  Total records:", nrow(final_data_clean), "\n")
cat("  Time span:", min(final_data_clean$PY, na.rm = TRUE), "-", 
    max(final_data_clean$PY, na.rm = TRUE), "\n")
cat("  Unique sources:", length(unique(final_data_clean$SO)), "\n")
cat("  Average citations:", round(mean(final_data_clean$TC, na.rm = TRUE), 2), "\n")

cat("\nReduction summary:\n")
cat("  Initial (before any dedup):", nrow(merged_data), "\n")
cat("  After automatic dedup:", nrow(final_data), "\n")
cat("  After advanced dedup:", nrow(final_data_clean), "\n")
cat("  Total duplicates removed:", nrow(merged_data) - nrow(final_data_clean), "\n")
cat("  Reduction rate:", round(100 * (nrow(merged_data) - nrow(final_data_clean)) / nrow(merged_data), 1), "%\n")

cat("\n=== READY FOR ANALYSIS ===\n")
cat("Next step: Run 05_descriptive_analysis.R\n")
