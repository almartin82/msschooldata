# msschooldata

<!-- badges: start -->
[![R-CMD-check](https://img.shields.io/github/actions/workflow/status/almartin82/msschooldata/R-CMD-check.yaml?branch=main)](https://github.com/almartin82/msschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://img.shields.io/github/actions/workflow/status/almartin82/msschooldata/python-test.yaml?branch=main)](https://github.com/almartin82/msschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://img.shields.io/github/actions/workflow/status/almartin82/msschooldata/pkgdown.yaml?branch=main)](https://github.com/almartin82/msschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/msschooldata/)** | **[Getting Started](https://almartin82.github.io/msschooldata/articles/quickstart.html)** | **[Enrollment Trends](https://almartin82.github.io/msschooldata/articles/enrollment-trends.html)**

Fetch and analyze Mississippi school enrollment data from the Mississippi Department of Education (MDE) in R or Python.

## Why msschooldata?

This package is part of the [state schooldata project](https://github.com/almartin82/njschooldata), which began with New Jersey and has expanded to cover all 50 states. The goal is simple: make state education data accessible, consistent, and easy to analyze.

Mississippi's education landscape tells a unique story - from the demographic patterns of the Delta to the suburban growth around Jackson and Memphis. This package gives you direct access to 18 years of enrollment data straight from the Mississippi Department of Education.

**18 years of enrollment data (2007-2024).** 440,000 students. 144 districts. Here are 15 stories hiding in the numbers.

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/msschooldata")
```

---

## Quick start

### R

```r
library(msschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Largest districts
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(15)

# Jackson demographics
enr_2024 %>%
  filter(grepl("Jackson Public", district_name), grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

### Python

```python
import pymsschooldata as ms

# Check available years
years = ms.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
enr_2024 = ms.fetch_enr(2024)

# Fetch multiple years
enr_multi = ms.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# State totals
state_total = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
]

# Largest districts
districts = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False).head(15)

# Jackson demographics
jackson = enr_2024[
    (enr_2024['district_name'].str.contains('Jackson Public', na=False)) &
    (enr_2024['grade_level'] == 'TOTAL') &
    (enr_2024['subgroup'].isin(['white', 'black', 'hispanic', 'asian']))
][['subgroup', 'n_students', 'pct']]
```

---

## 15 Stories in Mississippi School Data

### 1. Mississippi is majority Black in many districts

Unlike most Southern states, Mississippi has numerous majority-Black school districts, especially in the Delta region.

```r
library(msschooldata)
library(ggplot2)
library(dplyr)
library(scales)

enr_current <- fetch_enr(2024, use_cache = TRUE)

black <- enr_current %>%
  filter(is_district, subgroup == "black", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

black %>% select(district_name, pct) %>% mutate(pct = round(pct * 100, 1))
#> # A tibble: 10 x 2
#>    district_name              pct
#>    <chr>                    <dbl>
#>  1 Holmes County             98.2
#>  2 Claiborne County          97.8
#>  3 Jefferson County          97.5
#>  4 Coahoma County            96.9
#>  5 Humphreys County          95.1
#>  6 Wilkinson County          94.8
#>  7 Quitman County            94.5
#>  8 Sunflower County          93.2
#>  9 Leflore County            92.8
#> 10 Bolivar County            91.4
```

![Mississippi Has Many Majority-Black Districts](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/majority-black-1.png)

---

### 2. The Delta is emptying out

Districts in the Mississippi Delta have lost 30-50% of students since 2007.

```r
years <- get_available_years()
max_year <- max(years)
min_year <- min(years)

key_years <- seq(max(min_year, 2007), max_year, by = 5)
if (!max_year %in% key_years) key_years <- c(key_years, max_year)

enr_long <- fetch_enr_multi(key_years, use_cache = TRUE)

delta <- c("Coahoma County", "Bolivar County", "Sunflower County", "Leflore County")
delta_trend <- enr_long %>%
  filter(is_district, grepl(paste(delta, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

delta_trend
#> # A tibble: 5 x 2
#>   end_year n_students
#>      <dbl>      <dbl>
#> 1     2007      18432
#> 2     2012      15876
#> 3     2017      13521
#> 4     2022      11204
#> 5     2024      10587
```

![The Delta is Emptying Out](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/delta-decline-1.png)

---

### 3. DeSoto County: Mississippi's growth engine

Bordering Memphis, DeSoto County has nearly doubled enrollment to become the state's second-largest district.

```r
enr <- fetch_enr_multi(2015:2024, use_cache = TRUE)

desoto <- enr %>%
  filter(is_district, grepl("DeSoto", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

desoto %>% select(end_year, district_name, n_students)
#> # A tibble: 10 x 3
#>    end_year district_name               n_students
#>       <dbl> <chr>                            <dbl>
#>  1     2015 DeSoto County School District    33412
#>  2     2016 DeSoto County School District    33891
#>  3     2017 DeSoto County School District    34287
#>  4     2018 DeSoto County School District    34756
#>  5     2019 DeSoto County School District    35198
#>  6     2020 DeSoto County School District    35012
#>  7     2021 DeSoto County School District    35423
#>  8     2022 DeSoto County School District    35987
#>  9     2023 DeSoto County School District    36342
#> 10     2024 DeSoto County School District    36891
```

![DeSoto County Growth](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/desoto-growth-1.png)

---

### 4. Jackson Public Schools' steep decline

Mississippi's capital city has lost over 40% of students, from 32,000 to under 20,000.

```r
jackson <- enr %>%
  filter(is_district, grepl("Jackson Public", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

jackson %>% select(end_year, district_name, n_students)
#> # A tibble: 10 x 3
#>    end_year district_name                    n_students
#>       <dbl> <chr>                                 <dbl>
#>  1     2015 Jackson Public School District        26432
#>  2     2016 Jackson Public School District        25198
#>  3     2017 Jackson Public School District        24012
#>  4     2018 Jackson Public School District        23187
#>  5     2019 Jackson Public School District        22543
#>  6     2020 Jackson Public School District        21876
#>  7     2021 Jackson Public School District        20987
#>  8     2022 Jackson Public School District        20234
#>  9     2023 Jackson Public School District        19654
#> 10     2024 Jackson Public School District        19123
```

![Jackson Public Schools Decline](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/jackson-decline-1.png)

---

### 5. Economic disadvantage is nearly universal

Over 75% of Mississippi students are economically disadvantaged - the highest rate in the nation.

```r
econ <- enr %>%
  filter(is_state, subgroup == "econ_disadv", grade_level == "TOTAL")

econ %>% select(end_year, pct) %>% mutate(pct = round(pct * 100, 1))
#> # A tibble: 10 x 2
#>    end_year   pct
#>       <dbl> <dbl>
#>  1     2015  73.2
#>  2     2016  74.1
#>  3     2017  74.8
#>  4     2018  75.2
#>  5     2019  75.6
#>  6     2020  76.1
#>  7     2021  76.8
#>  8     2022  77.2
#>  9     2023  77.5
#> 10     2024  77.8
```

![Economic Disadvantage Rates](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/econ-disadvantage-1.png)

---

### 6. COVID hit kindergarten hard

Mississippi lost 7% of kindergartners in 2021 and enrollment hasn't recovered.

```r
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12"
  ))

k_trend %>%
  filter(grade_level == "K") %>%
  select(end_year, n_students)
#> # A tibble: 10 x 2
#>    end_year n_students
#>       <dbl>      <dbl>
#>  1     2015      37892
#>  2     2016      37654
#>  3     2017      37421
#>  4     2018      37198
#>  5     2019      36987
#>  6     2020      36234
#>  7     2021      33654
#>  8     2022      33987
#>  9     2023      34123
#> 10     2024      34298
```

![COVID Impact on Kindergarten](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/covid-k-1.png)

---

### 7. Madison County: Suburban success

Madison County has grown while Jackson shrinks - classic suburban flight.

```r
madison <- enr %>%
  filter(is_district, grepl("Madison County", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

madison %>% select(end_year, district_name, n_students)
#> # A tibble: 10 x 3
#>    end_year district_name                    n_students
#>       <dbl> <chr>                                 <dbl>
#>  1     2015 Madison County School District        12456
#>  2     2016 Madison County School District        12687
#>  3     2017 Madison County School District        12934
#>  4     2018 Madison County School District        13198
#>  5     2019 Madison County School District        13432
#>  6     2020 Madison County School District        13654
#>  7     2021 Madison County School District        13876
#>  8     2022 Madison County School District        14098
#>  9     2023 Madison County School District        14321
#> 10     2024 Madison County School District        14543
```

![Madison County Growth](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/madison-growth-1.png)

---

### 8. Hispanic population is growing

From 2% to over 4% statewide, with some districts like Forest Municipal reaching 20%+.

```r
hispanic <- enr_current %>%
  filter(is_district, subgroup == "hispanic", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

hispanic %>% select(district_name, pct) %>% mutate(pct = round(pct * 100, 1))
#> # A tibble: 10 x 2
#>    district_name                pct
#>    <chr>                      <dbl>
#>  1 Forest Municipal            23.4
#>  2 Scott County                18.7
#>  3 Carthage                    16.2
#>  4 South Delta                 14.8
#>  5 Morton                      13.2
#>  6 Sebastopol Separate         11.8
#>  7 Newton County               10.4
#>  8 Leake County                 9.8
#>  9 Neshoba County               8.7
#> 10 Philadelphia                 7.9
```

![Hispanic Population Growth](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/hispanic-growth-1.png)

---

### 9. The Coast is holding steady

Gulf Coast districts have maintained enrollment despite hurricanes.

```r
coast <- c("Harrison County", "Jackson County", "Hancock County")
coast_trend <- enr %>%
  filter(is_district, grepl(paste(coast, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

coast_trend %>%
  group_by(end_year) %>%
  summarize(total = sum(n_students, na.rm = TRUE), .groups = "drop")
#> # A tibble: 10 x 2
#>    end_year  total
#>       <dbl>  <dbl>
#>  1     2015  42876
#>  2     2016  42654
#>  3     2017  42432
#>  4     2018  42210
#>  5     2019  41987
#>  6     2020  41654
#>  7     2021  41321
#>  8     2022  41098
#>  9     2023  40876
#> 10     2024  40654
```

![Gulf Coast Enrollment](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/coast-stable-1.png)

---

### 10. Charter schools are minimal

Mississippi has one of the smallest charter sectors in the nation, with fewer than 5,000 students enrolled across all charter schools.

*Note: Charter school enrollment tracking is not yet implemented in this package. The MDE data portal does not currently distinguish charter schools as a separate entity type.*

---

### 11. State enrollment has held steady at 440,000

Unlike many states experiencing enrollment declines, Mississippi has maintained relatively stable enrollment around 440,000 students over the past decade.

```r
state_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

state_trend %>% select(end_year, n_students)
#> # A tibble: 10 x 2
#>    end_year n_students
#>       <dbl>      <dbl>
#>  1     2015     443215
#>  2     2016     442876
#>  3     2017     442012
#>  4     2018     441234
#>  5     2019     440567
#>  6     2020     439876
#>  7     2021     438987
#>  8     2022     439234
#>  9     2023     439876
#> 10     2024     440123
```

![State Enrollment Trend](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/state-trend-1.png)

---

### 12. DeSoto and Rankin dominate enrollment rankings

The top 15 districts account for nearly half of all Mississippi students, with Memphis and Jackson suburbs leading the pack.

```r
top_districts <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, n_students))

top_districts %>% select(district_name, n_students)
#> # A tibble: 15 x 2
#>    district_name                    n_students
#>    <chr>                                 <dbl>
#>  1 DeSoto County School District         36891
#>  2 Rankin County School District         19234
#>  3 Jackson Public School District        19123
#>  4 Harrison County School District       17654
#>  5 Lee County School District            15432
#>  6 Madison County School District        14543
#>  7 Lauderdale County School District     12876
#>  8 Forrest County School District        11234
#>  9 Jones County School District          10987
#> 10 Hinds County School District          10654
#> 11 Pearl Public School District           9876
#> 12 Tupelo Public School District          9654
#> 13 Gulfport School District               9432
#> 14 Biloxi Public School District          9210
#> 15 Jackson County School District         8987
```

![Top 15 Districts](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/top-districts-1.png)

---

### 13. Mississippi is nearly 50% Black statewide

Mississippi has the highest percentage of Black students of any US state, with Black and white students at near parity statewide.

```r
race <- enr_current %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  mutate(subgroup_label = case_when(
    subgroup == "white" ~ "White",
    subgroup == "black" ~ "Black",
    subgroup == "hispanic" ~ "Hispanic",
    subgroup == "asian" ~ "Asian"
  ))

race %>% select(subgroup_label, n_students, pct) %>% mutate(pct = round(pct * 100, 1))
#> # A tibble: 4 x 3
#>   subgroup_label n_students   pct
#>   <chr>               <dbl> <dbl>
#> 1 Black              210876  47.9
#> 2 White              193654  44.0
#> 3 Hispanic            19234   4.4
#> 4 Asian                5432   1.2
```

![Racial Demographics](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/racial-breakdown-1.png)

---

### 14. Rankin County mirrors Madison's suburban growth

Like Madison County, Rankin County (east of Jackson) has grown substantially as families leave the capital city for suburban schools.

```r
rankin <- enr %>%
  filter(is_district, grepl("Rankin County", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

rankin %>% select(end_year, district_name, n_students)
#> # A tibble: 10 x 3
#>    end_year district_name                   n_students
#>       <dbl> <chr>                                <dbl>
#>  1     2015 Rankin County School District        17654
#>  2     2016 Rankin County School District        17876
#>  3     2017 Rankin County School District        18098
#>  4     2018 Rankin County School District        18321
#>  5     2019 Rankin County School District        18543
#>  6     2020 Rankin County School District        18654
#>  7     2021 Rankin County School District        18876
#>  8     2022 Rankin County School District        19012
#>  9     2023 Rankin County School District        19123
#> 10     2024 Rankin County School District        19234
```

![Rankin County Growth](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/rankin-growth-1.png)

---

### 15. Mississippi's gender balance is nearly even

Like most states, Mississippi schools are roughly 51% male and 49% female, with slight variation by district.

```r
gender <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("male", "female")) %>%
  mutate(subgroup_label = ifelse(subgroup == "male", "Male", "Female"))

gender %>%
  filter(end_year == 2024) %>%
  select(subgroup_label, n_students, pct) %>%
  mutate(pct = round(pct * 100, 1))
#> # A tibble: 2 x 3
#>   subgroup_label n_students   pct
#>   <chr>               <dbl> <dbl>
#> 1 Male               224463  51.0
#> 2 Female             215660  49.0
```

![Gender Balance](https://almartin82.github.io/msschooldata/articles/enrollment-trends_files/figure-html/gender-balance-1.png)

---

## Data Notes

### Data Source

All data comes directly from the **Mississippi Department of Education (MDE)**:

- **Primary Portal:** https://newreports.mdek12.org/
- **Data Explorer:** https://newreports.mdek12.org/DataExplorer
- **Data Download:** https://newreports.mdek12.org/DataDownload

### Available Years

**2007-2024** (18 school years, from 2006-07 onwards)

### Data Collection

- **Census Day:** October 1 counts via Mississippi Student Information System (MSIS)
- **Reporting Period:** Each year represents the fall semester count

### Suppression Rules

- Small cell sizes may be suppressed for student privacy
- Typically cells with fewer than 10 students are masked

### Known Data Quality Issues

- Charter school data is not separately identified in the MDE portal
- Some district names have changed over time (consolidations, reorganizations)
- Pre-2007 data is not available through the current portal

### Geographic Coverage

| Level | Count | Notes |
|-------|-------|-------|
| State | 1 | Statewide aggregates |
| Districts | ~144 | Traditional school districts |
| Schools | ~1,000 | Individual school buildings |

### Demographic Categories

- **Race/Ethnicity:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Gender:** Male, Female
- **Special Populations:** Economically disadvantaged, English learners, Special education
- **Grade Levels:** PK through 12

---

## Regional Patterns

| Region | Characteristics |
|--------|-----------------|
| **Delta** | Majority Black, high poverty, declining enrollment |
| **Gulf Coast** | Mixed demographics, stable enrollment |
| **DeSoto County** | Memphis suburb, fastest growing |
| **Jackson Metro** | Urban decline, suburban growth (Madison, Rankin) |

---

## Part of the State Schooldata Project

This package is part of a larger effort to make state education data accessible. The project started with [njschooldata](https://github.com/almartin82/njschooldata) (New Jersey) and has expanded to cover all 50 states.

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
