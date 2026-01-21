# Install required packages (run once)
# required_pkgs <- c(
#  "tidyverse","stringdist","bibliometrix","lubridate","readr","tidytext",
#  "stm","topicmodels","quanteda","textstem","igraph","network","ggraph",
#  "changepoint","shiny","DT","writexl"
#)
# install_if_missing <- function(pkgs){
#  to_install <- pkgs[!(pkgs %in% installed.packages()[,1])]
#  if(length(to_install)) install.packages(to_install)
#}
#install_if_missing(required_pkgs)
# stm requires some system deps; if installation issues occur follow stm CRAN instructions.

# bibliometric_pipeline.R
library(tidyverse)
library(stringdist)
library(bibliometrix)   # optional, used for some helpers if input is in WoS/Scopus format
library(lubridate)
library(readr)
library(tidytext)
library(tidyr)
library(stm)
library(quanteda)
library(textstem)
library(topicmodels)
library(igraph)
library(ggraph)
library(changepoint)
library(writexl)

# ---------------------------
# 0. Configuration / filenames
# ---------------------------
input_file <- "scopus.csv"   # your Scopus/WoS CSV
prisma_out_xlsx <- "PRISMA_counts_and_records.xlsx"
clean_export_csv <- "bibliometrics_cleaned.csv"
fractional_results_xlsx <- "fractional_counts.xlsx"
stm_results_rds <- "stm_results.rds"
burst_results_csv <- "keyword_bursts.csv"

# ---------------------------
# 1. Read input (flexible)
# Expected columns (template below): id, title, abstract, authors, affiliations, year, journal, keywords, doi, citations, source, orcid_authors, country
# - authors: semicolon-separated "Last, First; Last2, First2"
# - affiliations: semicolon-separated corresponding institutions
# - keywords: semicolon-separated keywords (author keywords preferred)
# ---------------------------
# ---------------------------
# 2. Automatic delimiter detection + read input
# ---------------------------
detect_delim <- function(file, sample_lines = 5) {
   txt <- readLines(file, n = sample_lines, warn = FALSE)
   joined <- paste(txt, collapse = "\n")
   counts <- c(
     comma = stringr::str_count(joined, ","),
     semicolon = stringr::str_count(joined, ";"),
     tab = stringr::str_count(joined, "\t")
   )
   delim <- names(which.max(counts))
   if (counts[delim] == 0) delim <- "comma"
   switch(delim,
          comma = ",",
          semicolon = ";",
          tab = "\t")
 }
# 
delim_detected <- detect_delim(input_file)
cat("Detected delimiter:", shQuote(delim_detected), "\n")

df_raw <- read_delim(input_file, delim = delim_detected, show_col_types = FALSE)
cat("Rows read:", nrow(df_raw), "columns:", ncol(df_raw), "\n")

input_file <- read_csv("scopus.csv")

df_raw <- input_file

remove(input_file)
# ---------------------------
# 3. Basic cleaning
# ---------------------------
# --- Basic cleaning with automatic name normalization ---
library(janitor)
df_raw <- janitor::clean_names(df_raw)
trim_all <- function(x) ifelse(is.na(x), "", trimws(as.character(x)))

# print column names for verification
print(names(df_raw))

df_raw <- df_raw %>% rename(citations = cited_by)

df <- df_raw %>%
  mutate(across(where(is.character), ~trim_all(.x))) %>%
  mutate(
    year = if ("year" %in% names(.data)) suppressWarnings(as.integer(.data$year)) else NA_integer_,
    citations = if ("citations" %in% names(.data)) suppressWarnings(as.numeric(.data$citations)) else NA_real_
  )


# ---------------------------
# 4. Deduplication (DOI + fuzzy title)
# ---------------------------
# A: DOI-based
if("doi" %in% names(df)){
  df <- df %>% arrange(doi, year)
  df <- df[!duplicated(tolower(df$doi)), ]
}

# B: fuzzy title deduplication
titles <- df$title
dist_mat <- stringdistmatrix(tolower(titles), tolower(titles), method="jw")
diag(dist_mat) <- 1
dup_threshold <- 0.12
to_remove <- rep(FALSE, nrow(df))
for(i in seq_len(nrow(dist_mat))){
  if(!to_remove[i]){
    similar <- which(dist_mat[i,] <= dup_threshold)
    if(length(similar)>0){
      to_remove[similar[similar>i]] <- TRUE
    }
  }
}
df_clean <- df[!to_remove, ]
cat("Deduplication reduced records from", nrow(df), "to", nrow(df_clean), "\n")

# PRISMA counts
prisma_df <- tibble(
  stage = c("records_identified","records_after_deduplication","records_screened",
            "full_text_assessed","full_text_excluded","studies_included"),
 n_records = c(nrow(df))
)
write_xlsx(list(PRISMA=prisma_df), prisma_out_xlsx)
cat("PRISMA table saved to", prisma_out_xlsx, "\n")

# ---------------------------
# 5. Keyword normalization & author parsing
# ---------------------------
normalize_keywords <- function(k){
  if(is.na(k) || k=="") return(NA_character_)
  kw <- unlist(strsplit(k, ";|,"))
  kw <- trimws(tolower(kw))
  kw <- kw[kw!=""]
  kw <- stringr::str_replace_all(kw, "[-_/]", " ")
  kw <- textstem::lemmatize_words(kw)
  kw <- unique(kw)
  paste(kw, collapse="; ")
}
df_clean <- df_raw %>%
  mutate(keywords_norm = map_chr(author_keywords, normalize_keywords),
         title_norm = tolower(title),
         abstract_norm = tolower(abstract))

df_clean <- df_clean %>%
  mutate(
    author_list = strsplit(authors, ";"),
    affiliation_list = strsplit(affiliations, ";")
  )

# ---------------------------
# 6. Fractional counting
# ---------------------------
fractional_author_table <- df_clean %>%
  mutate(n_authors = map_int(author_list, length)) %>%
  unnest_longer(author_list) %>%
  group_by(author_list) %>%
  summarise(frac_count = sum(1 / pmax(n_authors,1)),
            n_pubs = n_distinct(id)) %>%
  arrange(desc(frac_count))

df_aff <- df_clean %>%
  mutate(n_aff = map_int(affiliation_list, length)) %>%
  unnest_longer(affiliation_list) %>%
  group_by(affiliation_list) %>%
  summarise(frac_count = sum(1 / pmax(n_aff,1)),
            n_pubs = n_distinct(id)) %>%
  arrange(desc(frac_count))

write_xlsx(list(authors=fractional_author_table, affiliations=df_aff), fractional_results_xlsx)
cat("Fractional counts saved to", fractional_results_xlsx, "\n")

# ---------------------------
# 7. Keyword-year burst detection
# ---------------------------
kw_long <- df_clean %>%
  select(id, year, keywords_norm) %>%
  filter(!is.na(keywords_norm) & keywords_norm != "") %>%
  mutate(keywords_list = strsplit(keywords_norm, ";\\s*")) %>%
  unnest_longer(keywords_list) %>%
  mutate(keywords_list = trimws(keywords_list)) %>%
  group_by(keywords_list, year) %>%
  summarise(n = n(), .groups = "drop")

years <- seq(min(df_clean$year, na.rm=TRUE), max(df_clean$year, na.rm=TRUE))
kw_full <- kw_long %>%
  group_by(keywords_list) %>%
  complete(year = years, fill = list(n=0)) %>%
  ungroup()

detect_bursts_changepoint <- function(counts, minseglen = 2){
  if(max(counts)==0) return(integer(0))
  cp <- cpt.meanvar(counts, method="PELT", minseglen=minseglen)
  cpts(cp)
}

burst_results <- kw_full %>%
  group_by(keywords_list) %>%
  summarise(bursts = list(detect_bursts_changepoint(n)), .groups="drop") %>%
  mutate(burst_detected = map_lgl(bursts, ~length(.x)>0))
write_csv(burst_results %>% unnest_wider(bursts), burst_results_csv)
cat("Keyword burst results saved to", burst_results_csv, "\n")

# ---------------------------
# 8. Dynamic Topic Modeling (STM)
# ---------------------------
df_text <- df_clean %>%
  mutate(text = ifelse(abstract_norm=="", title_norm, paste(title_norm, abstract_norm, sep=". "))) %>%
  filter(!is.na(text) & str_trim(text)!="") %>%
  mutate(doc_id = row_number())

corpus_df <- corpus(df_text, text_field="text", docid_field="doc_id")
tokens_df <- tokens(corpus_df, remove_punct=TRUE, remove_numbers=TRUE) %>%
  tokens_tolower() %>%
  tokens_remove(stopwords("en")) %>%
  tokens_wordstem()

dfm_mat <- dfm(tokens_df)
dfm_trimmed <- dfm_trim(dfm_mat, min_termfreq=5)
prep <- convert(dfm_trimmed, to="stm")
docs <- prep$documents
vocab <- prep$vocab
meta <- df_text %>% select(doc_id, year) %>% mutate(year=as.numeric(year))

K <- 8
set.seed(42)
stm_fit <- stm(documents=docs, vocab=vocab, K=K,
               prevalence=~s(year), data=meta,
               max.em.its=75, init.type="Spectral")
saveRDS(stm_fit, stm_results_rds)
cat("STM fitted and saved to", stm_results_rds, "\n")

topic_prev <- data.frame(year = seq(min(meta$year, na.rm=TRUE), max(meta$year, na.rm=TRUE)))
for(k in 1:K){
  est <- estimateEffect(k ~ s(year), stmobj=stm_fit, metadata=meta, uncertainty="Global")
  pred <- predict(est, newdata=data.frame(year=topic_prev$year), topics=k)
  topic_prev[[paste0("topic",k)]] <- pred
}
write_csv(topic_prev, "topic_prevalence_by_year.csv")
cat("Topic prevalence saved to topic_prevalence_by_year.csv\n")

# ---------------------------
# 9. Co-authorship network (optional)
# ---------------------------
coauth_edges <- df_clean %>%
  select(id, author_list) %>%
  unnest_longer(author_list) %>%
  group_by(id) %>%
  summarise(authors=list(author_list), .groups="drop") %>%
  mutate(pairs = map(authors, ~ t(combn(unlist(.x), 2)) %>% as_tibble(.name_repair="unique"))) %>%
  unnest(pairs) %>%
  rename(author1=V1, author2=V2) %>%
  group_by(author1, author2) %>%
  summarise(weight=n(), .groups="drop")

g <- graph_from_data_frame(coauth_edges, directed=FALSE)
V(g)$degree <- degree(g)
V(g)$betweenness <- betweenness(g)
cent_table <- tibble(author=V(g)$name, degree=V(g)$degree, betweenness=V(g)$betweenness)
write_xlsx(list(centrality=cent_table), "coauthorship_centrality.xlsx")
cat("Co-authorship centrality saved to coauthorship_centrality.xlsx\n")

# ---------------------------
# 10. Export cleaned CSV for Shiny app
# ---------------------------
df_export <- df_clean %>%
  mutate(id = ifelse(is.na(id) | id=="", paste0("rec", row_number()), id)) %>%
  select(id, title, abstract, authors, affiliations, year, journal,
         keywords_norm, doi, citations, source)
write_csv(df_export, clean_export_csv)
cat("Cleaned CSV exported to", clean_export_csv, "\n")

# ---------------------------
# 11. Summary of outputs
# ---------------------------
cat("\nPipeline complete! Outputs generated:\n",
    "-", prisma_out_xlsx, "\n",
    "-", fractional_results_xlsx, "\n",
    "-", burst_results_csv, "\n",
    "-", stm_results_rds, "\n",
    "-", "topic_prevalence_by_year.csv\n",
    "-", "coauthorship_centrality.xlsx\n",
    "-", clean_export_csv, "\n")