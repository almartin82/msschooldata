# Identify enrollment aggregation levels

Adds boolean flags to identify state, district, school, and charter
records.

## Usage

``` r
id_enr_aggs(df)
```

## Arguments

- df:

  Enrollment dataframe, output of tidy_enr

## Value

data.frame with boolean aggregation flags (is_state, is_district,
is_school, is_campus, is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
tidy_data <- fetch_enr(2024)
# Data already has aggregation flags via id_enr_aggs
table(tidy_data$is_state, tidy_data$is_district, tidy_data$is_school)
# Charter schools are identified by name pattern
sum(tidy_data$is_charter)
} # }
```
