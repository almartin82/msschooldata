# Generate placeholder data structure

Creates an empty data frame with the expected column structure when data
cannot be downloaded. This allows the package to work offline and shows
users the expected format.

## Usage

``` r
generate_placeholder_data(end_year, entity_type)
```

## Arguments

- end_year:

  School year end

- entity_type:

  "School" or "District"

## Value

Empty data frame with expected columns
