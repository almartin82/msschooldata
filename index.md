# msschooldata

**[Documentation](https://almartin82.github.io/msschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/msschooldata/articles/quickstart.html)**

Fetch and analyze Mississippi school enrollment data from the
Mississippi Department of Education (MDE) in R or Python.

## What can you find with msschooldata?

**19 years of enrollment data (2007-2025).** 440,000 students. 144
districts. Here are ten stories hiding in the numbers:

------------------------------------------------------------------------

### 1. Mississippi is majority Black in many districts

Unlike most Southern states, Mississippi has numerous majority-Black
school districts, especially in the Delta region.

``` r
library(msschooldata)
library(dplyr)

enr_2025 <- fetch_enr(2025)

enr_2025 %>%
  filter(is_district, subgroup == "black", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(district_name, n_students, pct) %>%
  head(10)
```

------------------------------------------------------------------------

### 2. The Delta is emptying out

Districts in the Mississippi Delta (Coahoma, Bolivar, Sunflower,
Leflore) have lost 30-50% of students since 2007.

``` r
enr <- fetch_enr_multi(c(2007, 2012, 2017, 2022, 2025))

delta <- c("Coahoma County", "Bolivar County", "Sunflower County", "Leflore County")

enr %>%
  filter(is_district, grepl(paste(delta, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, district_name, n_students)
```

------------------------------------------------------------------------

### 3. DeSoto County: Mississippi’s growth engine

Bordering Memphis, DeSoto County has nearly doubled enrollment to become
the state’s second-largest district.

``` r
enr %>%
  filter(is_district, grepl("DeSoto", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

------------------------------------------------------------------------

### 4. Jackson Public Schools’ steep decline

Mississippi’s capital city has lost over 40% of students, from 32,000 to
under 20,000.

``` r
enr %>%
  filter(is_district, grepl("Jackson Public", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

------------------------------------------------------------------------

### 5. Economic disadvantage is nearly universal

Over 75% of Mississippi students are economically disadvantaged - the
highest rate in the nation.

``` r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_state, subgroup == "econ_disadv", grade_level == "TOTAL") %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(end_year, n_students, pct)
```

------------------------------------------------------------------------

### 6. COVID hit kindergarten hard

Mississippi lost 7% of kindergartners in 2021 and enrollment hasn’t
recovered.

``` r
enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  select(end_year, grade_level, n_students)
```

------------------------------------------------------------------------

### 7. Madison County: A suburban success

Madison County (north of Jackson) has grown while Jackson itself
shrinks - classic suburban flight.

``` r
enr %>%
  filter(is_district, grepl("Madison County", district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

------------------------------------------------------------------------

### 8. Hispanic population is growing

From 2% to over 4% statewide, with some districts like Forest Municipal
reaching 20%+.

``` r
enr_2025 %>%
  filter(is_district, subgroup == "hispanic", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(district_name, n_students, pct) %>%
  head(10)
```

------------------------------------------------------------------------

### 9. The Coast is holding steady

Gulf Coast districts (Harrison, Jackson County, Hancock) have maintained
enrollment despite hurricanes.

``` r
coast <- c("Harrison County", "Jackson County", "Hancock County")

enr %>%
  filter(is_district, grepl(paste(coast, collapse = "|"), district_name),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, district_name, n_students)
```

------------------------------------------------------------------------

### 10. Charter schools are minimal

Mississippi has one of the smallest charter sectors - under 5,000
students in the entire state.

``` r
enr_2025 %>%
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  summarize(
    total_charter = sum(n_students, na.rm = TRUE),
    n_schools = n()
  )
```

------------------------------------------------------------------------

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/msschooldata")
```

## Quick start

### R

``` r
library(msschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Largest districts
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(15)

# Jackson demographics
enr_2025 %>%
  filter(grepl("Jackson Public", district_name), grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

### Python

``` python
import pymsschooldata as ms

# Check available years
years = ms.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
enr_2025 = ms.fetch_enr(2025)

# Fetch multiple years
enr_multi = ms.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])

# State totals
state_total = enr_2025[
    (enr_2025['is_state'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
]

# Largest districts
districts = enr_2025[
    (enr_2025['is_district'] == True) &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False).head(15)

# Jackson demographics
jackson = enr_2025[
    (enr_2025['district_name'].str.contains('Jackson Public', na=False)) &
    (enr_2025['grade_level'] == 'TOTAL') &
    (enr_2025['subgroup'].isin(['white', 'black', 'hispanic', 'asian']))
][['subgroup', 'n_students', 'pct']]
```

## Data availability

| Years         | Source                    | Notes                                 |
|---------------|---------------------------|---------------------------------------|
| **2007-2025** | MDE newreports.mdek12.org | Data from 2006-07 school year onwards |

Data is sourced from the Mississippi Department of Education: - Primary
Portal: <https://newreports.mdek12.org/> - Data Explorer:
<https://newreports.mdek12.org/DataExplorer> - Data Download:
<https://newreports.mdek12.org/DataDownload>

### What’s included

- **Levels:** State, District (144), School
- **Demographics:** White, Black, Hispanic, Asian, Native American,
  Pacific Islander, Multiracial
- **Gender:** Male, Female
- **Special populations:** Economically disadvantaged, English learners,
  Special education
- **Grade levels:** PK through 12

### Mississippi-specific notes

- Mississippi has approximately **144 school districts** and **1,000+
  public schools**
- Total enrollment is approximately **440,000 students**
- **District IDs:** Typically 4-digit codes
- **School IDs:** District code plus additional digits
- **Data collection:** Mississippi Student Information System (MSIS),
  October 1 counts
- **Charter sector:** Very small by law - limited authorization
- **Data suppression:** Small cell sizes may be suppressed for privacy

### Regional patterns

| Region            | Characteristics                                    |
|-------------------|----------------------------------------------------|
| **Delta**         | Majority Black, high poverty, declining enrollment |
| **Gulf Coast**    | Mixed demographics, stable enrollment              |
| **DeSoto County** | Memphis suburb, fastest growing                    |
| **Jackson Metro** | Urban decline, suburban growth                     |

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT
