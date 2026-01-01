# Claude Code Instructions for msschooldata

## Project Context

This is an R package for fetching and processing Mississippi school
enrollment data from the Mississippi Department of Education (MDE).

### Key Data Characteristics

- **Data Source**: Mississippi Department of Education (MDE) at
  <https://newreports.mdek12.org/>
- **Data System**: Mississippi Student Information System (MSIS)
- **ID System**:
  - District IDs: Typically 4 digits
  - School IDs: District ID + additional digits
- **Number of Districts**: ~144
- **Available Years**: 2007-present (2006-07 school year onwards)

### Data Portal Details

- **Primary Portal**: <https://newreports.mdek12.org/>
- **Data Explorer**: <https://newreports.mdek12.org/DataExplorer>
  (interactive)
- **Data Download**: <https://newreports.mdek12.org/DataDownload> (bulk
  exports)
- **Legacy Portal**: <https://reports.mde.k12.ms.us/> (older data)

### Format Eras

| Era    | Years     | Source                | Notes                     |
|--------|-----------|-----------------------|---------------------------|
| Modern | 2007-2025 | newreports.mdek12.org | JSON API or Excel exports |

## Package Structure

The package follows the same patterns as txschooldata and other state
packages: - `fetch_enrollment.R` - Main user-facing function -
`get_raw_enrollment.R` - Download raw data from MDE -
`process_enrollment.R` - Process raw data into standard schema -
`tidy_enrollment.R` - Transform to long format - `cache.R` - Local
caching functions - `utils.R` - Utility functions

## Standard Output Schema

All state packages use consistent column names: - `end_year`: School
year end (2024 = 2023-24) - `district_id`, `campus_id`/`school_id`:
Entity identifiers - `district_name`, `campus_name`/`school_name`:
Entity names - `type`: “State”, “District”, or “School” - Demographics:
`white`, `black`, `hispanic`, `asian`, `native_american`,
`pacific_islander`, `multiracial` - Special populations: `econ_disadv`,
`lep`, `special_ed` - Grade levels: `grade_pk`, `grade_k`, `grade_01`
through `grade_12`
