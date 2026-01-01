# msschooldata: Fetch and Process Mississippi School Data

Downloads and processes school data from the Mississippi Department of
Education (MDE). Provides functions for fetching enrollment data from
the MDE reporting system and transforming it into tidy format for
analysis. Data is sourced from the Mississippi Student Information
System (MSIS) and includes enrollment counts by grade, race/ethnicity,
gender, and special populations from 2006 to present.

The msschooldata package provides functions for downloading, processing,
and analyzing school enrollment data from the Mississippi Department of
Education (MDE). Data is sourced from the MDE reporting system at
newreports.mdek12.org.

## Data Source

Mississippi Department of Education (MDE) provides enrollment data
through their public reporting portal. Data is collected via the
Mississippi Student Information System (MSIS) and reflects enrollment
counts as of October 1 of each school year.

## Available Data

- Years: 2007 to present (2006-07 school year onwards)

- Aggregation levels: State, District, School

- Demographics: Race/ethnicity (7 categories), gender

- Special populations: Economically disadvantaged, LEP, Special
  Education

- Grade levels: PK through 12

## Main Functions

- [`fetch_enr`](https://almartin82.github.io/msschooldata/reference/fetch_enr.md):

  Download enrollment data for a single year

- [`fetch_enr_multi`](https://almartin82.github.io/msschooldata/reference/fetch_enr_multi.md):

  Download enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/msschooldata/reference/tidy_enr.md):

  Transform wide format to long/tidy format

- [`get_available_years`](https://almartin82.github.io/msschooldata/reference/get_available_years.md):

  List available data years

## Caching

Downloaded data is cached locally to avoid repeated downloads. Use
[`cache_status`](https://almartin82.github.io/msschooldata/reference/cache_status.md)
to see cached files and
[`clear_cache`](https://almartin82.github.io/msschooldata/reference/clear_cache.md)
to remove them.

## See also

Useful links:

- <https://github.com/almartin82/msschooldata>

- Report bugs at <https://github.com/almartin82/msschooldata/issues>

Useful links:

- <https://github.com/almartin82/msschooldata>

- Report bugs at <https://github.com/almartin82/msschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
