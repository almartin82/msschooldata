#!/usr/bin/env Rscript
# Generate README figures for msschooldata

library(ggplot2)
library(dplyr)
library(scales)
devtools::load_all(".")

# Create figures directory
dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

# Theme
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6")

# Get available years (handles both vector and list return types)
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
message("Fetching data...")
enr <- fetch_enr_multi((max_year - 9):max_year)
key_years <- seq(max(min_year, 2007), max_year, by = 5)
if (!max_year %in% key_years) key_years <- c(key_years, max_year)
enr_long <- fetch_enr_multi(key_years)
enr_current <- fetch_enr(max_year)

# 1. Majority Black districts
message("Creating majority Black chart...")
black <- enr_current %>%
  filter(is_district, subgroup == "black", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

p <- ggplot(black, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["black"]) +
  coord_flip() +
  labs(title = "Mississippi Has Many Majority-Black Districts",
       subtitle = "Especially in the Delta region",
       x = "", y = "Percent Black Students") +
  theme_readme()
ggsave("man/figures/majority-black.png", p, width = 10, height = 6, dpi = 150)

# 2. Delta decline
message("Creating Delta decline chart...")
delta <- c("Coahoma County", "Bolivar County", "Sunflower County", "Leflore County")
delta_trend <- enr_long %>%
  filter(is_district, grepl(paste(delta, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p <- ggplot(delta_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "The Delta is Emptying Out",
       subtitle = "Coahoma, Bolivar, Sunflower, Leflore counties combined",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/delta-decline.png", p, width = 10, height = 6, dpi = 150)

# 3. DeSoto growth
message("Creating DeSoto growth chart...")
desoto <- enr %>%
  filter(is_district, grepl("DeSoto", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(desoto, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "DeSoto County: Mississippi's Growth Engine",
       subtitle = "Memphis suburb nearly doubled enrollment",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/desoto-growth.png", p, width = 10, height = 6, dpi = 150)

# 4. Jackson decline
message("Creating Jackson decline chart...")
jackson <- enr %>%
  filter(is_district, grepl("Jackson Public", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(jackson, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Jackson Public Schools' Steep Decline",
       subtitle = "Capital city lost over 40% of students",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/jackson-decline.png", p, width = 10, height = 6, dpi = 150)

# 5. Economic disadvantage
message("Creating econ disadvantage chart...")
econ <- enr %>%
  filter(is_state, subgroup == "econ_disadv", grade_level == "TOTAL")

p <- ggplot(econ, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  labs(title = "Economic Disadvantage is Nearly Universal",
       subtitle = "Over 75% of Mississippi students - highest in the nation",
       x = "School Year", y = "Percent Economically Disadvantaged") +
  theme_readme()
ggsave("man/figures/econ-disadvantage.png", p, width = 10, height = 6, dpi = 150)

# 6. COVID kindergarten
message("Creating COVID K chart...")
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12"
  ))

p <- ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Hit Mississippi Kindergarten Hard",
       subtitle = "Lost 7% of kindergartners and hasn't recovered",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/covid-k.png", p, width = 10, height = 6, dpi = 150)

# 7. Madison growth
message("Creating Madison growth chart...")
madison <- enr %>%
  filter(is_district, grepl("Madison County", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(madison, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Madison County: Suburban Success",
       subtitle = "Growing while Jackson shrinks - classic suburban flight",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/madison-growth.png", p, width = 10, height = 6, dpi = 150)

# 8. Hispanic growth
message("Creating Hispanic growth chart...")
hispanic <- enr_current %>%
  filter(is_district, subgroup == "hispanic", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

p <- ggplot(hispanic, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["hispanic"]) +
  coord_flip() +
  labs(title = "Hispanic Population Growing",
       subtitle = "Some districts like Forest Municipal reaching 20%+",
       x = "", y = "Percent Hispanic Students") +
  theme_readme()
ggsave("man/figures/hispanic-growth.png", p, width = 10, height = 6, dpi = 150)

# 9. Coast stable
message("Creating coast stable chart...")
coast <- c("Harrison County", "Jackson County", "Hancock County")
coast_trend <- enr %>%
  filter(is_district, grepl(paste(coast, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(coast_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "The Coast is Holding Steady",
       subtitle = "Gulf Coast districts maintained enrollment despite hurricanes",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/coast-stable.png", p, width = 10, height = 6, dpi = 150)

# 10. Charter small
message("Creating charter small chart...")
charter <- enr %>%
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p <- ggplot(charter, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Charter Schools are Minimal",
       subtitle = "Under 5,000 students - one of smallest sectors in the nation",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/charter-small.png", p, width = 10, height = 6, dpi = 150)

message("Done! Generated 10 figures in man/figures/")
