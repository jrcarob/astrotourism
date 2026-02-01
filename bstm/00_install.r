# ============================================================================
# STBM ANALYSIS - STEP 00: INSTALL REQUIRED PACKAGES
# ============================================================================
# Purpose: Install all necessary R packages for bibliometric analysis
# Run this script ONCE before starting analysis
# Estimated time: 5-10 minutes depending on internet speed
# ============================================================================

cat("Installing required packages for STBM Analysis...\n\n")

# Core bibliometric packages
cat("Installing bibliometrix...\n")
install.packages("bibliometrix")

cat("Installing openalexR...\n")
install.packages("openalexR")

# Data manipulation packages
cat("Installing data manipulation packages...\n")
install.packages("dplyr")
install.packages("tidyr")
install.packages("stringr")

# Visualization packages
cat("Installing visualization packages...\n")
install.packages("ggplot2")
install.packages("patchwork")
install.packages("treemapify")

# Network analysis
cat("Installing network analysis packages...\n")
install.packages("igraph")
install.packages("networkD3")

# Geographic visualization
cat("Installing geographic packages...\n")
install.packages("rworldmap")

# Additional utilities
cat("Installing utility packages...\n")
install.packages("jsonlite")

# Verify installation
cat("\n=== VERIFYING INSTALLATION ===\n\n")
packages <- c("bibliometrix", "dplyr", "tidyr", "stringr", "ggplot2", 
              "igraph", "openalexR", "networkD3", "jsonlite")

installation_status <- data.frame(
  Package = packages,
  Status = sapply(packages, function(pkg) {
    if(require(pkg, character.only = TRUE, quietly = TRUE)) {
      return("✓ OK")
    } else {
      return("✗ FAILED")
    }
  })
)

print(installation_status)

cat("\n=== INSTALLATION SUMMARY ===\n")
cat("Packages installed:", sum(grepl("OK", installation_status$Status)), "/", nrow(installation_status), "\n")

if(all(grepl("OK", installation_status$Status))) {
  cat("\n✓ All packages installed successfully!\n")
  cat("Next step: Run 01_setup_project.R\n")
} else {
  cat("\n✗ Some packages failed to install. Please check error messages above.\n")
}
