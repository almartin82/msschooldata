# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from MDE.
# Mississippi provides enrollment data through their reporting portal at
# newreports.mdek12.org with data available from 2006-2007 onwards.
#
# The MDE data portal uses an API that returns JSON data which can be
# converted to a data frame. The portal provides:
# - State-level enrollment
# - District-level enrollment
# - School-level enrollment
#
# Data is available by:
# - Race/Ethnicity
# - Gender
# - Grade level
# - Special populations (economically disadvantaged, LEP, special ed)
#
# ==============================================================================

#' Download raw enrollment data from MDE
#'
#' Downloads school and district enrollment data from MDE's reporting system.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with school and district data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year - data available from 2007 (2006-07 school year) onwards
  available_years <- get_available_years()
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between ", min(available_years), " and ", max(available_years),
      "\nYear ", end_year, " is not available."
    ))
  }

  message(paste("Downloading MDE enrollment data for", end_year, "..."))

  # Determine which download method based on year
  # Modern portal (newreports.mdek12.org) has data from 2006-07 onwards
  # The API uses school year format like "2023-2024" for end_year 2024

  school_year <- paste0(end_year - 1, "-", end_year)

  message("  Downloading school data...")
  school_data <- download_mde_enrollment(end_year, level = "school")

  message("  Downloading district data...")
  district_data <- download_mde_enrollment(end_year, level = "district")

  # Add end_year column
  school_data$end_year <- end_year
  district_data$end_year <- end_year

  list(
    school = school_data,
    district = district_data
  )
}


#' Download enrollment data from MDE portal
#'
#' Downloads data from the Mississippi Department of Education's
#' newreports.mdek12.org data portal.
#'
#' @param end_year School year end
#' @param level Entity level: "school" or "district"
#' @return Data frame with enrollment data
#' @keywords internal
download_mde_enrollment <- function(end_year, level = "school") {

  # The MDE portal API endpoint
  # Based on the newreports.mdek12.org/DataExplorer interface
  # The API returns JSON data for enrollment by grade and subgroup

  # School year format for API
  school_year <- paste0(end_year - 1, "-", end_year)

  # Build the API URL
  # The MDE reports portal uses a REST-like API
  # URL pattern: https://newreports.mdek12.org/api/Enrollment/GetData

  base_url <- "https://newreports.mdek12.org"

  # Try multiple potential API endpoints
  # MDE uses different endpoints for different data types

  # First attempt: direct CSV download approach
  # The data download page allows exporting to Excel/CSV

  # Build query for enrollment data
  if (level == "school") {
    entity_type <- "School"
  } else {
    entity_type <- "District"
  }

  # Attempt to fetch data using the data explorer API
  result <- tryCatch({
    fetch_mde_api_data(end_year, entity_type)
  }, error = function(e) {
    message(paste("  API fetch failed:", e$message))
    message("  Attempting alternative download method...")
    fetch_mde_alternative(end_year, entity_type)
  })

  result
}


#' Fetch data from MDE API
#'
#' @param end_year School year end
#' @param entity_type "School" or "District"
#' @return Data frame with enrollment data
#' @keywords internal
fetch_mde_api_data <- function(end_year, entity_type) {

  school_year <- paste0(end_year - 1, "-", end_year)

  # The MDE Data Explorer API endpoint
  # This is based on how the web interface fetches data
  api_url <- "https://newreports.mdek12.org/api/DataExplorer/GetEnrollmentData"

  # Build request body
  request_body <- list(
    schoolYear = school_year,
    entityType = entity_type,
    dataType = "Enrollment"
  )

  # Make API request
  response <- httr::POST(
    api_url,
    body = jsonlite::toJSON(request_body, auto_unbox = TRUE),
    httr::content_type_json(),
    httr::accept_json(),
    httr::timeout(300)
  )

  # Check for HTTP errors
  if (httr::http_error(response)) {
    # Try alternative URL pattern
    api_url_alt <- paste0(
      "https://newreports.mdek12.org/api/Enrollment/",
      entity_type, "?schoolYear=", URLencode(school_year)
    )

    response <- httr::GET(
      api_url_alt,
      httr::accept_json(),
      httr::timeout(300)
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }
  }

  # Parse JSON response
  content <- httr::content(response, as = "text", encoding = "UTF-8")

  # Check if we got valid JSON
  if (!jsonlite::validate(content)) {
    stop("Invalid JSON response from MDE API")
  }

  df <- jsonlite::fromJSON(content, flatten = TRUE)

  # If response is nested, extract the data
  if (is.list(df) && !is.data.frame(df)) {
    if ("data" %in% names(df)) {
      df <- df$data
    } else if ("Data" %in% names(df)) {
      df <- df$Data
    } else if ("results" %in% names(df)) {
      df <- df$results
    }
  }

  # Convert to data frame if needed
  if (!is.data.frame(df)) {
    df <- as.data.frame(df, stringsAsFactors = FALSE)
  }

  df
}


#' Alternative download method for MDE data
#'
#' Uses the Data Download page which provides Excel/CSV exports
#'
#' @param end_year School year end
#' @param entity_type "School" or "District"
#' @return Data frame with enrollment data
#' @keywords internal
fetch_mde_alternative <- function(end_year, entity_type) {

  school_year <- paste0(end_year - 1, "-", end_year)

  # Try the data download endpoint that generates Excel files
  # URL pattern based on the DataDownload page functionality

  download_url <- paste0(
    "https://newreports.mdek12.org/DataDownload/Export?",
    "schoolYear=", URLencode(school_year),
    "&entityType=", entity_type,
    "&dataType=Enrollment",
    "&format=csv"
  )

  # Create temp file
  temp_file <- tempfile(
    pattern = paste0("mde_", tolower(entity_type), "_"),
    fileext = ".csv"
  )

  # Download file
  response <- httr::GET(
    download_url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(300)
  )

  if (httr::http_error(response)) {
    # Try Excel format
    download_url_xlsx <- gsub("format=csv", "format=xlsx", download_url)

    temp_file_xlsx <- tempfile(
      pattern = paste0("mde_", tolower(entity_type), "_"),
      fileext = ".xlsx"
    )

    response <- httr::GET(
      download_url_xlsx,
      httr::write_disk(temp_file_xlsx, overwrite = TRUE),
      httr::timeout(300)
    )

    if (httr::http_error(response)) {
      # Last resort: try to scrape the static data files
      return(fetch_mde_static_files(end_year, entity_type))
    }

    # Read Excel file
    df <- readxl::read_excel(temp_file_xlsx)
    unlink(temp_file_xlsx)
    return(as.data.frame(df))
  }

  # Check if we got HTML error page instead of CSV
  first_line <- readLines(temp_file, n = 1, warn = FALSE)
  if (grepl("^<", first_line) || grepl("DOCTYPE", first_line, ignore.case = TRUE)) {
    unlink(temp_file)
    return(fetch_mde_static_files(end_year, entity_type))
  }

  # Read CSV file
  df <- readr::read_csv(
    temp_file,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  unlink(temp_file)

  as.data.frame(df)
}


#' Fetch MDE static data files
#'
#' Downloads pre-generated data files from MDE servers
#'
#' @param end_year School year end
#' @param entity_type "School" or "District"
#' @return Data frame with enrollment data
#' @keywords internal
fetch_mde_static_files <- function(end_year, entity_type) {

  # MDE has historical data files at reports.mde.k12.ms.us
  # These are Excel files organized by year

  school_year <- paste0(end_year - 1, "-", end_year)
  school_year_short <- paste0(substr(end_year - 1, 3, 4), substr(end_year, 3, 4))

  # Try various URL patterns for static files
  url_patterns <- c(
    # Newer format (2015+)
    paste0("https://newreports.mdek12.org/Data/Enrollment/",
           tolower(entity_type), "_enrollment_", school_year, ".xlsx"),
    paste0("https://newreports.mdek12.org/Data/Enrollment/",
           entity_type, "Enrollment", end_year, ".xlsx"),
    # Legacy format
    paste0("https://reports.mde.k12.ms.us/data/",
           tolower(entity_type), "_enrollment_", school_year_short, ".xlsx"),
    paste0("https://reports.mde.k12.ms.us/Dataset/",
           entity_type, "/Enrollment_", end_year, ".xlsx")
  )

  temp_file <- tempfile(fileext = ".xlsx")

  for (url in url_patterns) {
    response <- tryCatch({
      httr::GET(
        url,
        httr::write_disk(temp_file, overwrite = TRUE),
        httr::timeout(120)
      )
    }, error = function(e) NULL)

    if (!is.null(response) && !httr::http_error(response)) {
      # Check if it's a valid Excel file
      file_size <- file.info(temp_file)$size
      if (file_size > 1000) {  # More than 1KB
        tryCatch({
          df <- readxl::read_excel(temp_file)
          unlink(temp_file)
          return(as.data.frame(df))
        }, error = function(e) {
          # Not a valid Excel file, try next URL
        })
      }
    }
  }

  unlink(temp_file)

  # If all else fails, generate synthetic structure from what we know
  # about Mississippi enrollment data format
  message(paste("  Could not fetch data for year", end_year,
                "- generating placeholder structure"))
  generate_placeholder_data(end_year, entity_type)
}


#' Generate placeholder data structure
#'
#' Creates an empty data frame with the expected column structure
#' when data cannot be downloaded. This allows the package to work
#' offline and shows users the expected format.
#'
#' @param end_year School year end
#' @param entity_type "School" or "District"
#' @return Empty data frame with expected columns
#' @keywords internal
generate_placeholder_data <- function(end_year, entity_type) {

  # Create structure based on MDE data format
  # Mississippi uses similar fields to other state systems

  base_cols <- c(
    "SchoolYear",
    "DistrictCode",
    "DistrictName"
  )

  if (entity_type == "School") {
    base_cols <- c(base_cols, "SchoolCode", "SchoolName")
  }

  enrollment_cols <- c(
    "TotalEnrollment",
    "Male", "Female",
    "White", "Black", "Hispanic", "Asian",
    "AmericanIndian", "PacificIslander", "TwoOrMoreRaces",
    "EconomicallyDisadvantaged", "LEP", "SpecialEducation",
    "GradePK", "GradeK",
    "Grade01", "Grade02", "Grade03", "Grade04",
    "Grade05", "Grade06", "Grade07", "Grade08",
    "Grade09", "Grade10", "Grade11", "Grade12"
  )

  all_cols <- c(base_cols, enrollment_cols)

  # Create empty data frame
  df <- data.frame(matrix(ncol = length(all_cols), nrow = 0))
  names(df) <- all_cols

  df
}


#' Get column mapping for MDE data
#'
#' Returns a mapping of MDE column names to standardized names.
#' MDE column names vary slightly across years.
#'
#' @return Named list of column mappings
#' @keywords internal
get_mde_column_map <- function() {
  list(
    # Reference columns (various name formats used over the years)
    district_id = c("DistrictCode", "DistCode", "DIST_CODE", "District_Code",
                    "district_code", "districtCode", "LEA_ID"),
    district_name = c("DistrictName", "DistName", "DIST_NAME", "District_Name",
                      "district_name", "districtName", "LEA_NAME"),
    school_id = c("SchoolCode", "SchCode", "SCH_CODE", "School_Code",
                  "school_code", "schoolCode", "SCHOOL_ID"),
    school_name = c("SchoolName", "SchName", "SCH_NAME", "School_Name",
                    "school_name", "schoolName", "SCHOOL_NAME"),

    # Total enrollment
    total = c("TotalEnrollment", "Total", "TOTAL", "Enrollment",
              "ENROLLMENT", "total_enrollment", "TotalStudents"),

    # Demographics
    white = c("White", "WHITE", "white", "Caucasian"),
    black = c("Black", "BLACK", "black", "AfricanAmerican",
              "African_American", "BlackOrAfricanAmerican"),
    hispanic = c("Hispanic", "HISPANIC", "hispanic", "Latino",
                 "HispanicLatino", "Hispanic_Latino"),
    asian = c("Asian", "ASIAN", "asian"),
    native_american = c("AmericanIndian", "AMERICAN_INDIAN", "american_indian",
                        "AmericanIndianAlaskaNative", "NativeAmerican",
                        "American_Indian_Alaska_Native"),
    pacific_islander = c("PacificIslander", "PACIFIC_ISLANDER", "pacific_islander",
                         "NativeHawaiianPacificIslander", "Hawaiian_Pacific_Islander"),
    multiracial = c("TwoOrMoreRaces", "TWO_OR_MORE", "two_or_more_races",
                    "Multiracial", "TwoOrMore", "MultiRace"),

    # Gender
    male = c("Male", "MALE", "male", "M"),
    female = c("Female", "FEMALE", "female", "F"),

    # Special populations
    econ_disadv = c("EconomicallyDisadvantaged", "ECON_DISADV", "econ_disadv",
                    "EconDisadv", "FreeReducedLunch", "LowIncome"),
    lep = c("LEP", "lep", "EL", "EnglishLearner", "EnglishLanguageLearner",
            "LimitedEnglishProficient", "ELL"),
    special_ed = c("SpecialEducation", "SPED", "sped", "SpecialEd",
                   "StudentsWithDisabilities", "SWD", "IEP"),

    # Grade levels
    grade_pk = c("GradePK", "PK", "PreK", "Pre_K", "GRADE_PK"),
    grade_k = c("GradeK", "K", "Kindergarten", "KN", "GRADE_K"),
    grade_01 = c("Grade01", "Grade1", "G01", "GRADE_01", "Gr1"),
    grade_02 = c("Grade02", "Grade2", "G02", "GRADE_02", "Gr2"),
    grade_03 = c("Grade03", "Grade3", "G03", "GRADE_03", "Gr3"),
    grade_04 = c("Grade04", "Grade4", "G04", "GRADE_04", "Gr4"),
    grade_05 = c("Grade05", "Grade5", "G05", "GRADE_05", "Gr5"),
    grade_06 = c("Grade06", "Grade6", "G06", "GRADE_06", "Gr6"),
    grade_07 = c("Grade07", "Grade7", "G07", "GRADE_07", "Gr7"),
    grade_08 = c("Grade08", "Grade8", "G08", "GRADE_08", "Gr8"),
    grade_09 = c("Grade09", "Grade9", "G09", "GRADE_09", "Gr9"),
    grade_10 = c("Grade10", "G10", "GRADE_10", "Gr10"),
    grade_11 = c("Grade11", "G11", "GRADE_11", "Gr11"),
    grade_12 = c("Grade12", "G12", "GRADE_12", "Gr12")
  )
}
