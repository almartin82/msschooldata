# msschooldata

An R package for fetching, processing, and analyzing school enrollment data from the Mississippi Department of Education (MDE).

## Installation

You can install the development version of msschooldata from GitHub:

```r
# install.packages("devtools")
devtools::install_github("almartin82/msschooldata")
```

## Quick Start

```r
library(msschooldata)

# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# View state totals
state_totals <- enr_2024 %>%
  dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Get wide format (one row per school/district)
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2024)
```

## Data Source

Data is sourced from the **Mississippi Department of Education** through their public reporting portal:

- **Primary Portal**: [newreports.mdek12.org](https://newreports.mdek12.org/)
- **Data Explorer**: [newreports.mdek12.org/DataExplorer](https://newreports.mdek12.org/DataExplorer)
- **Data Download**: [newreports.mdek12.org/DataDownload](https://newreports.mdek12.org/DataDownload)

Enrollment data is collected through the **Mississippi Student Information System (MSIS)** and reflects student counts as of October 1 of each school year.

## Data Availability

### Years Available

| Era | Years | Notes |
|-----|-------|-------|
| Modern Portal | 2007-2025 | Data from 2006-07 school year onwards via newreports.mdek12.org |

**Earliest available year**: 2007 (2006-07 school year)
**Most recent available year**: 2025 (2024-25 school year, as published)
**Total years of data**: 19 years

### Aggregation Levels

- **State**: Statewide totals
- **District**: All 144 school districts in Mississippi
- **School**: Individual public schools

### Demographics

Race/ethnicity categories (available for all years):
- White
- Black/African American
- Hispanic/Latino
- Asian
- American Indian/Alaska Native
- Native Hawaiian/Pacific Islander
- Two or More Races

Gender:
- Male
- Female

### Special Populations

- Economically Disadvantaged (Free/Reduced Lunch eligible)
- Limited English Proficient (LEP) / English Learners (EL)
- Special Education (Students with Disabilities)

### Grade Levels

- Pre-Kindergarten (PK)
- Kindergarten (K)
- Grades 1-12

## Output Format

### Tidy Format (default)

When `tidy = TRUE` (the default), data is returned in long format:

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24 school year) |
| type | character | "State", "District", or "School" |
| district_id | character | District identifier |
| school_id | character | School identifier (NA for district/state rows) |
| campus_id | character | Alias for school_id (compatibility) |
| district_name | character | District name |
| school_name | character | School name |
| campus_name | character | Alias for school_name (compatibility) |
| grade_level | character | "TOTAL", "PK", "K", "01"-"12" |
| subgroup | character | "total_enrollment", "white", "black", etc. |
| n_students | integer | Student count |
| pct | numeric | Percentage of total (0-1 scale) |
| is_state | logical | TRUE for state-level rows |
| is_district | logical | TRUE for district-level rows |
| is_school | logical | TRUE for school-level rows |
| is_campus | logical | Alias for is_school (compatibility) |

### Wide Format

When `tidy = FALSE`, data is returned with one row per entity:

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| type | character | Aggregation level |
| district_id | character | District identifier |
| school_id | character | School identifier |
| district_name | character | District name |
| school_name | character | School name |
| row_total | integer | Total enrollment |
| white, black, hispanic, ... | integer | Demographic counts |
| male, female | integer | Gender counts |
| econ_disadv, lep, special_ed | integer | Special population counts |
| grade_pk, grade_k, grade_01, ... | integer | Grade-level counts |

## Caching

Downloaded data is cached locally to avoid repeated downloads:

```r
# View cached files
cache_status()

# Clear cache for a specific year
clear_cache(2024)

# Clear all cached data
clear_cache()

# Force fresh download (ignore cache)
fresh_data <- fetch_enr(2024, use_cache = FALSE)
```

Cache is stored in:
- macOS: `~/Library/Caches/msschooldata/data/`
- Windows: `%LOCALAPPDATA%/msschooldata/data/`
- Linux: `~/.cache/msschooldata/data/`

## Known Caveats

1. **Data Suppression**: Small cell sizes may be suppressed to protect student privacy. Suppressed values are returned as NA.

2. **API Availability**: The MDE data portal may occasionally be unavailable. If download fails, try again later or use cached data.

3. **Historical Data**: While the portal advertises data from 2006 onwards, some years may have incomplete or differently structured data.

4. **Charter Schools**: Charter schools are included in the data as regular schools. Mississippi has a relatively small charter school sector.

5. **Consolidations and Closures**: School and district IDs may change over time due to consolidations, mergers, or closures.

## Mississippi Education Context

- Mississippi has approximately **144 school districts** and **1,000+ public schools**
- Total enrollment is approximately **440,000 students**
- District identifiers are typically 4-digit codes
- School identifiers include the district code plus additional digits

## Examples

### State Enrollment Trends

```r
library(msschooldata)
library(dplyr)
library(ggplot2)

# Get 5 years of data
enr <- fetch_enr_multi(2020:2024)

# Plot state total over time
enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  ggplot(aes(x = end_year, y = n_students)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::comma) +
  labs(title = "Mississippi Public School Enrollment",
       x = "School Year End",
       y = "Total Students")
```

### District Comparison

```r
# Get 2024 data
enr_2024 <- fetch_enr(2024)

# Find largest districts
largest_districts <- enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10)

print(largest_districts)
```

### Demographic Analysis

```r
# State demographics
demographics <- enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)

print(demographics)
```

## Related Packages

This package is part of the state-schooldata family:
- [txschooldata](https://github.com/almartin82/txschooldata) - Texas
- [ilschooldata](https://github.com/almartin82/ilschooldata) - Illinois
- [nyschooldata](https://github.com/almartin82/nyschooldata) - New York
- [ohschooldata](https://github.com/almartin82/ohschooldata) - Ohio
- [paschooldata](https://github.com/almartin82/paschooldata) - Pennsylvania
- [caschooldata](https://github.com/almartin82/caschooldata) - California

## License

MIT License

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
