# ============================================================
#  Burst → STM topic mapping table
# ============================================================

library(tidyverse)
library(stm)
library(tidytext)

# ---------------------------
# 1. Load inputs
# ---------------------------
burst_file <- "keyword_bursts.csv"
stm_file   <- "stm_results.rds"

bursts <- read_csv(burst_file, show_col_types = FALSE)
stm_fit <- readRDS(stm_file)

# Keep only detected bursts
bursts <- bursts %>%
  filter(burst_detected == TRUE) %>%
  distinct(keywords_list)

# ---------------------------
# 2. Extract STM word–topic probabilities
# ---------------------------
beta <- tidy(stm_fit, matrix = "beta")
# beta columns: topic, term, beta

# ---------------------------
# 3. Map each burst keyword to STM topics
# ---------------------------
burst_topic_map <- beta %>%
  filter(term %in% bursts$keywords_list) %>%
  group_by(term) %>%
  arrange(desc(beta)) %>%
  summarise(
    dominant_topic = first(topic),
    dominant_beta  = first(beta),
    secondary_topic = ifelse(n() > 1, nth(topic, 2), NA_integer_),
    secondary_beta  = ifelse(n() > 1, nth(beta, 2), NA_real_),
    .groups = "drop"
  ) %>%
  rename(burst_keyword = term)

# ---------------------------
# 4. Assign burst wave by first appearance year (if available)
# ---------------------------
if ("year" %in% names(bursts)) {
  burst_wave <- bursts %>%
    group_by(keywords_list) %>%
    summarise(burst_onset_year = min(year, na.rm = TRUE),
              .groups = "drop") %>%
    mutate(
      burst_wave = case_when(
        burst_onset_year <= 2012 ~ "Early",
        burst_onset_year <= 2018 ~ "Intermediate",
        TRUE ~ "Recent"
      )
    )
  
  burst_topic_map <- burst_topic_map %>%
    left_join(burst_wave, by = c("burst_keyword" = "keywords_list"))
} else {
  burst_topic_map <- burst_topic_map %>%
    mutate(burst_wave = NA_character_,
           burst_onset_year = NA_integer_)
}

# ---------------------------
# 5. Add topic labels (edit as needed)
# ---------------------------
topic_labels <- tibble(
  topic = 1:7,
  topic_label = c(
    "Astronomy & observation",
    "Environmental impacts",
    "Protected areas & governance",
    "Cultural heritage & destination development",
    "Public engagement & education",
    "Tourist experience & activities",
    "Policy, planning & regulation"
  )
)

burst_topic_map <- burst_topic_map %>%
  left_join(topic_labels, by = c("dominant_topic" = "topic")) %>%
  rename(dominant_topic_label = topic_label) %>%
  left_join(topic_labels, by = c("secondary_topic" = "topic")) %>%
  rename(secondary_topic_label = topic_label)

# ---------------------------
# 6. Final table formatting
# ---------------------------
burst_topic_table <- burst_topic_map %>%
  arrange(burst_wave, dominant_topic) %>%
  select(
    burst_wave,
    burst_keyword,
    dominant_topic,
    dominant_topic_label,
    secondary_topic,
    secondary_topic_label,
    burst_onset_year
  )

# ---------------------------
# 7. Export
# ---------------------------
write_csv(burst_topic_table,
          "outputs/Table_burst_to_STM_topics.csv")

burst_topic_table
