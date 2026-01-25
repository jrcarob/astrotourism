# Astrotourism — Reproducible pipeline outputs and provenance

This repository contains a bibliometric analysis pipeline for "Astrotourism". This README documents every output the pipeline produces, the provenance (how each file is generated), required inputs, software environment and package recommendations, and instructions so users can trace provenance and reproduce the results and the outputs exactly (or approximately).

---

## Table of contents

- Overview
- Inputs (required)
- How to run
- Software environment & reproducibility
- Parameters and key settings
- Outputs (files produced) — descriptions + provenance
- Data provenance & processing log
- Troubleshooting & common errors
- Archival / Zenodo suggestions
- License & contact

---

## Overview

This project reads bibliographic export(s) (e.g., Scopus, Web of Science), cleans and deduplicates records, computes fractional counts, detects keyword bursts, fits an STM topic model, generates topic prevalence over time, and builds a co-authorship network.

The main script is `pipeline.R`. It is a self-contained analysis pipeline with numbered sections; each section writes one or more output files. Use the "Outputs" section below to find the origin of each file.

---

## Inputs (required)

Primary input:
- `scopus.csv` (default name expected by the pipeline) — a CSV export from Scopus (or any bibliographic source) with the following (recommended) columns:
  - `id` (optional; if missing the pipeline will create stable `rec<N>` ids)
  - `title`
  - `abstract`
  - `authors` — semicolon-separated "Last, First; Last2, First2"
  - `affiliations` — semicolon-separated, aligned with authors (optional)
  - `year` — numeric year (if missing, set to NA)
  - `journal` (or source)
  - `author_keywords` (semicolons or commas separated preferred)
  - `doi` (optional)
  - `citations` or `cited_by` (pipeline normalizes `cited_by` -> `citations`)
  - `source`, `orcid_authors`, `country` (optional)

Notes:
- The pipeline includes automatic delimiter detection (comma/semicolon/tab) but the default is a CSV named `scopus.csv`. To use another filename, modify `pipeline.R` or pass it before invoking the script.
- Column names are cleaned via `janitor::clean_names()` early in the script, so case/spacing is relaxed but the above semantic columns are expected.

---

## How to run

Basic usage (from project root):

- Interactive R:
  1. Open `R` or RStudio in this repository.
  2. Install required packages (see "Software environment" below).
  3. Source or run the pipeline:
     ```r
     source("pipeline.R")       # runs the whole pipeline (interactive)
     # OR use Rscript for non-interactive:
     system("Rscript pipeline.R")
     ```

- Non-interactive:
  ```bash
  Rscript pipeline.R
  ```

The script prints progress messages and writes outputs into the repository root (or paths configured in the script).

---

## Software environment & reproducibility

Recommended R (example): R >= 4.0.0. Use a reproducible package environment (renv or packrat) when archiving.

Primary R packages used (see `pipeline.R` top of file):
- tidyverse (dplyr, tidyr, readr, tibble, purrr, ggplot2, etc.)
- stringdist
- bibliometrix (optional; for some helpers)
- lubridate
- tidytext
- stm
- quanteda
- textstem
- topicmodels
- igraph
- ggraph
- changepoint
- writexl
- readr
- janitor

Suggested reproducible setup (example using renv):
```r
install.packages("renv")
renv::init()           # or renv::restore() if renv.lock is provided
# then install any missing packages listed above, or run:
# source("pipeline.R") which will fail until packages are installed
```

Seed and deterministic settings:
- The pipeline sets `set.seed(42)` prior to STM fitting to make topic initialization deterministic across runs when STM uses random starts. Note that some nondeterminism may remain across platforms / package versions.
- If you need bitwise reproducibility, record R version, OS, and package versions (see below).

Recommended provenance capture (run before/after pipeline):
```r
# Write session info to file to capture package versions
writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
# Optionally save installed packages/versions snapshot
writeLines(utils::capture.output(utils::installed.packages()[,c("Package","Version")]), "installed_packages.txt")
```

---

## Parameters and key settings

Important parameters (can be changed in `pipeline.R` near the top or in the corresponding section):
- Deduplication by title similarity:
  - `dup_threshold` (default in script: 0.12) — maximum Jaro-Winkler distance to treat titles as duplicates; adjust if many false merges occur.
- STM:
  - `K` — number of topics (default in script: 8).
  - `max.em.its` — max EM iterations for STM (default 75 in script).
  - `init.type` — initialization strategy (default "Spectral").
  - `set.seed(42)` is used for reproducibility.
- Keyword burst detection:
  - changepoint `minseglen` default in function `detect_bursts_changepoint` is 2; adjust as needed.
- Tokenization / DFM:
  - `dfm_trim(..., min_termfreq = 5)` — minimum term frequency threshold before STM.

Document all parameter changes and the exact script commit when reproducing your archived results.

---

## Outputs (files produced) — descriptions and provenance

Below is a complete list of output files the pipeline produces (names correspond to variables in `pipeline.R`). For each file we list:
- filename(s)
- file format
- description
- provenance: which section / code in `pipeline.R` writes it (and what data / steps produced it)
- recommended checks

1. `PRISMA_counts_and_records.xlsx`
   - Format: Excel (.xlsx)
   - Description: PRISMA-style counts (records identified, after deduplication, screened, included, etc.)
   - Provenance: Section "PRISMA counts" — produced after deduplication. Written with `writexl::write_xlsx()` using `prisma_df`.
   - Check: Open to confirm `n_records` values and that `records_after_deduplication` matches `nrow(df_clean)`.

2. `bibliometrics_cleaned.csv` (variable: `clean_export_csv`)
   - Format: CSV
   - Description: Cleaned and normalized bibliographic table for downstream use / Shiny app.
   - Provenance: Section "Export cleaned CSV for Shiny app" — created from `df_clean`, selecting standardized fields and ensuring `id` exists.
   - Check: Contains columns `id, title, abstract, authors, affiliations, year, journal, keywords_norm, doi, citations, source`.

3. `fractional_counts.xlsx` (variable: `fractional_results_xlsx`)
   - Format: Excel (.xlsx) with multiple sheets
   - Sheets:
     - `authors` — fractional author counts and number of publications
     - `affiliations` — fractional affiliation counts and number of publications
   - Provenance: Section "Fractional counting" — computed from `df_clean` using `unnest_longer()` on `author_list` / `affiliation_list` and `map_int()` author/aff counts. Written with `write_xlsx()` where the list `list(authors=fractional_author_table, affiliations=df_aff)` is saved.
   - Check: Sort by `frac_count` descending; `n_pubs` should be integer count of distinct `id` per author/affiliation.

4. `keyword_bursts.csv` (variable: `burst_results_csv`)
   - Format: CSV
   - Description: Results of keyword burst detection per keyword, with detection flag and change-point indices (format depends on `pipeline.R` final formatting: either collapsed string, long rows, or wide columns).
   - Provenance: Section "Keyword-year burst detection" — keywords split and counted by year, complete over full year range, `detect_bursts_changepoint()` applies `changepoint::cpt.meanvar()` and cpts are collected. Written using `write_csv()` after formatting.
   - Check: For each `keywords_list` you should see `bursts` or `bursts_str` and `burst_detected` columns. Confirm year coverage is the full `years` sequence.

5. `stm_results.rds` (variable: `stm_results_rds`)
   - Format: RDS (R serialized object)
   - Description: Fitted STM model object (`stm_fit`) — contains `theta` (doc-topic proportions), `beta`, and other model objects necessary to reproduce topic-word lists and downstream analyses.
   - Provenance: Section "Dynamic Topic Modeling (STM)" — fitted via `stm()` with `prevalence = ~ s(year)` and saved with `saveRDS(stm_fit, stm_results_rds)`.
   - Check: load with `readRDS()` to inspect `class(stm_fit)` and `dim(stm_fit$theta)`.

6. `topic_prevalence_by_year.csv`
   - Format: CSV
   - Description: Year-by-year estimated topic prevalence (prior pipeline used `estimateEffect` + `predict` originally; the robust reproducible approach uses `stm_fit$theta` and averages proportions per year).
   - Provenance: Section "Topic prevalence by year" — computed from `stm_fit$theta` and `meta$year`; written with `write_csv(topic_prev, "topic_prevalence_by_year.csv")`.
   - Check: Columns `year`, `topic1`, `topic2`, ... `topicK`. Values are mean topic proportions across documents for that year.

7. `topic_prevalence_all_topics_facet.png` (and per-topic PNGs)
   - Format: PNG image(s)
   - Description: Visualizations of topic prevalence over time (faceted and/or per-topic images). May include outputs saved by both base `plot.estimateEffect()` and ggplot2-based approaches.
   - Provenance: Optional plotting sections; files are created by `ggsave()` and `png()`/`dev.off()` calls in plotting blocks. If both plotting approaches were run, you'll see:
     - `topic_plots_estimateEffect/` (PNG files, one per topic)
     - `topic_plots_ggplot/` (PNG files, one per topic)
     - `topic_prevalence_all_topics_facet.png` — combined faceted ggplot
   - Check: Ensure K panels present and labels/topwords are legible.

8. `coauthorship_centrality.xlsx`
   - Format: Excel (.xlsx)
   - Description: Node-level centrality measures computed on the co-authorship network (degree, betweenness, etc.).
   - Provenance: Section "Co-authorship network" — graph constructed using `igraph` from `coauth_edges` (`author1`, `author2`, `weight`), centrality computed and saved with `write_xlsx(list(centrality=cent_table), "coauthorship_centrality.xlsx")`.
   - Check: Confirm authors match the nodes of the graph and `degree` values match `igraph::degree(g)`.

9. `topic_plots_estimateEffect/` (directory)
   - Format: PNG files
   - Description: Per-topic PNGs created via `plot.estimateEffect()` (one file per topic).
   - Provenance: Plotting code that loops over topics and saves PNG via `png()` + `plot.estimateEffect()` + `dev.off()`.

10. `topic_plots_ggplot/` (directory)
    - Format: PNG files
    - Description: Per-topic ggplot2 PNGs (mean ± CI ribbons, point size by number of docs) produced from `stm_fit$theta` aggregated by `meta$year`.
    - Provenance: ggplot2 block; files created via `ggsave()`.

11. `sessionInfo.txt` (recommended)
    - Format: Plain text
    - Description: Snapshot of R `sessionInfo()` for exact package versions; recommended to create and archive with results.
    - Provenance: Not written by default by the pipeline — create with:
      ```r
      writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
      ```

12. `installed_packages.txt` (recommended)
    - Format: Plain text
    - Description: Snapshot of installed packages and versions
    - Provenance: Recommended to run before archiving to help reproducibility.

---

## Data provenance & processing log

The key transformation steps in `pipeline.R` are grouped and commented. When archiving, record:
- The exact `pipeline.R` commit SHA or tag used to produce the results.
- The input file(s) (e.g., `scopus.csv`) and their checksums (MD5/SHA256). Example:
  ```bash
  sha256sum scopus.csv > scopus.csv.sha256
  ```
- The `sessionInfo()` output (saved to `sessionInfo.txt`) to capture R and package versions.

Suggested provenance block to include in the Zenodo deposit metadata or as a small text file `PROVENANCE.txt`:

- Repository: GitHub: `jrcarob/Astrotourism`
- Pipeline script: `pipeline.R` (commit: <commit-hash used>)
- Input file: `scopus.csv` (SHA256: <sha256-here>)
- R version: `<R x.y.z>` (see `sessionInfo.txt`)
- Packages: See `sessionInfo.txt` (or `installed_packages.txt`)
- Random seed: 42 (used for STM initialization)
- Key parameters: `dup_threshold=0.12`, `K=<value used>`, `min_termfreq=5`, `minseglen=2` (keywords), `max.em.its=75` (STM)
- Notes: Any manual edits to pipeline parameters should be recorded here.

---

## Troubleshooting & common errors

- "Column `id` not found": Create stable `id` column early (on `df` or `df_clean`) using:
  ```r
  df <- df %>% mutate(id = ifelse(is.na(id) | id=="", paste0("rec", row_number()), id))
  ```
  or ensure your input has an `id` field.

- `n_distinct()` complaining about a function: Usually due to missing column `id` causing NSE to pick a function. Use `.data$id` or ensure `id` exists.

- `combn()` "n < m": combn requires at least 2 authors — filter or guard single-author rows before creating coauthor pairs.

- `tokens()` method not found for "corpus": Use `quanteda::tokens(as.character(df_text$text))` or ensure correct `quanteda` version & that `corpus` objects are created with `quanteda::corpus()`.

- `estimateEffect` + `predict` error: `estimateEffect` objects are plotted with `plot.estimateEffect()`; programmatic predictions can be derived directly from `stm_fit$theta`.

- `unnest_wider()` "Can't unnest elements with missing names": For list-columns like `bursts`, either collapse to string with `map_chr()` or use `unnest_longer()` or pad lists to equal length and use `names_sep` for `unnest_wider()`.

If you encounter an error, capture the small reproducible context:
```r
print(head(names(df_clean)))
dput(head(df_clean, 3))
```
and include the exact error + the few rows when requesting help.

---

## Archival / Zenodo suggestions

When archiving, include:
- `pipeline.R` (exact script used)
- Input data, if permissible by copyright (or a synthetic subset for privacy)
- `sessionInfo.txt`
- `installed_packages.txt` or `renv.lock`
- All outputs listed above
- A `CITATION.cff` or `CITATION` file so Zenodo can generate citations
- A short `PROVENANCE.txt` listing commit hash, seed, input checksums and parameter settings

Example Zenodo metadata fields:
- Title: "Astrotourism — bibliometric analysis pipeline and downstream results"
- Authors: add contributor names and ORCIDs
- Description: short summary + link to GitHub repo + brief provenance table
- Keywords: bibliometrics, STM, co-authorship, astrotourism, changepoint

---

## License & contact

- Default: Please choose a license for this repository (e.g. MIT, CC-BY for data/figures, or CC0 if you want to waive rights). Add `LICENSE` file to the repository and mention it here.
- Contact / Maintainer: `jrcarob` (GitHub login). Add an email or ORCID if you want people to contact you for reproducibility questions.

---

## Example quick reproducible checklist

1. Clone this repository (record commit SHA).
2. Place `scopus.csv` into repository root and compute checksum:
   ```bash
   sha256sum scopus.csv > scopus.csv.sha256
   ```
3. Start R with a clean session, install packages (or `renv::restore()`).
4. Run:
   ```r
   source("pipeline.R")
   writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
   ```
5. Archive outputs and the `sessionInfo.txt` along with the script and input checksum.
