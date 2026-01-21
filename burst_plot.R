# ============================================================
#  Figure X: STM topic prevalence + keyword burst periods
# ============================================================

library(tidyverse)
library(stm)
library(scales)

# ---------------------------
# 1. Load inputs
# ---------------------------
stm_fit <- readRDS("stm_results.rds")
topic_prev <- read_csv("topic_prevalence_by_year.csv", show_col_types = FALSE)
bursts <- read_csv("keyword_bursts.csv", show_col_types = FALSE)

# ---------------------------
# 2. Prepare topic prevalence (long format)
# ---------------------------
topic_long <- topic_prev %>%
  pivot_longer(
    cols = starts_with("topic"),
    names_to = "topic",
    values_to = "prevalence"
  ) %>%
  mutate(
    topic = as.integer(str_remove(topic, "topic"))
  )

# ---------------------------
# 3. Prepare burst data
# ---------------------------
# Expected columns: keywords_list, burst_detected, burst_start, burst_end
bursts_plot <- bursts %>%
  filter(burst_detected == TRUE) %>%
  rename(
    keyword = keywords_list
  )

# If your file has change-point indices instead of years:
# bursts_plot <- bursts_plot %>%
#   mutate(burst_start = year[min_cp],
#          burst_end   = year[max_cp])

# Assign burst waves by onset year
bursts_plot <- bursts_plot %>%
  mutate(
    burst_wave = case_when(
      burst_start <= 2012 ~ "Early",
      burst_start <= 2018 ~ "Intermediate",
      TRUE ~ "Recent"
    )
  )

# Order keywords by burst onset
bursts_plot <- bursts_plot %>%
  arrange(burst_start) %>%
  mutate(keyword = factor(keyword, levels = unique(keyword)))

# ---------------------------
# 4. Topic labels (edit to match your STM)
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

topic_long <- topic_long %>%
  left_join(topic_labels, by = "topic")

# ---------------------------
# 5. Plot
# ---------------------------
p <- ggplot() +
  
  # Topic prevalence curves
  geom_line(
    data = topic_long,
    aes(x = year, y = prevalence, color = topic_label),
    linewidth = 1,
    alpha = 0.9
  ) +
  
  # Burst bars (stacked at bottom)
  geom_segment(
    data = bursts_plot,
    aes(
      x = burst_start,
      xend = burst_end,
      y = -0.002 * as.numeric(keyword),
      yend = -0.002 * as.numeric(keyword),
      color = burst_wave
    ),
    linewidth = 3,
    lineend = "round"
  ) +
  
  scale_y_continuous(
    name = "Topic prevalence (STM estimate)",
    labels = percent_format(accuracy = 0.1),
    sec.axis = dup_axis(name = NULL)
  ) +
  
  scale_color_brewer(palette = "Set2") +
  
  labs(
    x = "Publication year",
    color = "Topic / Burst wave",
    title = "Temporal alignment of STM topic prevalence and keyword bursts"
  ) +
  
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "right",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

# ---------------------------
# 6. Save figure
# ---------------------------
ggsave(
  filename = "outputs/Figure_bursts_and_topic_prevalence.png",
  plot = p,
  width = 10,
  height = 6,
  dpi = 300
)

p
