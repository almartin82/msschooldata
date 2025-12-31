# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw MDE enrollment data into a
# clean, standardized format.
#
# ==============================================================================

#' Process raw MDE enrollment data
#'
#' Transforms raw MDE data into a standardized schema combining school
#' and district data.
#'
#' @param raw_data List containing school and district data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process school data
  school_processed <- process_school_enr(raw_data$school, end_year)

  # Process district data
  district_processed <- process_district_enr(raw_data$district, end_year)

  # Create state aggregate
  state_processed <- create_state_aggregate(district_processed, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, district_processed, school_processed)

  result
}


#' Process school-level enrollment data
#'
#' @param df Raw school data frame
#' @param end_year School year end
#' @return Processed school data frame
#' @keywords internal
process_school_enr <- function(df, end_year) {

  # Handle empty data
  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_result(end_year, "School"))
  }

  cols <- names(df)
  n_rows <- nrow(df)
  col_map <- get_mde_column_map()

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      # Try exact match first
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe with same number of rows as input
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("School", n_rows),
    stringsAsFactors = FALSE
  )

  # IDs
  district_col <- find_col(col_map$district_id)
  if (!is.null(district_col)) {
    result$district_id <- as.character(trimws(df[[district_col]]))
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  school_col <- find_col(col_map$school_id)
  if (!is.null(school_col)) {
    result$school_id <- as.character(trimws(df[[school_col]]))
  } else {
    result$school_id <- rep(NA_character_, n_rows)
  }

  # For consistency with other state packages, use campus_id
  result$campus_id <- result$school_id

  # Names
  district_name_col <- find_col(col_map$district_name)
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(df[[district_name_col]])
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  school_name_col <- find_col(col_map$school_name)
  if (!is.null(school_name_col)) {
    result$school_name <- trimws(df[[school_name_col]])
  } else {
    result$school_name <- rep(NA_character_, n_rows)
  }

  # For consistency with other state packages, use campus_name
  result$campus_name <- result$school_name

  # Total enrollment
  total_col <- find_col(col_map$total)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    result$row_total <- rep(NA_integer_, n_rows)
  }

  # Demographics
  demo_cols <- c("white", "black", "hispanic", "asian",
                 "native_american", "pacific_islander", "multiracial")

  for (name in demo_cols) {
    col <- find_col(col_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Gender
  male_col <- find_col(col_map$male)
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(col_map$female)
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Special populations
  special_cols <- c("econ_disadv", "lep", "special_ed")

  for (name in special_cols) {
    col <- find_col(col_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_cols <- c("grade_pk", "grade_k",
                  "grade_01", "grade_02", "grade_03", "grade_04",
                  "grade_05", "grade_06", "grade_07", "grade_08",
                  "grade_09", "grade_10", "grade_11", "grade_12")

  for (name in grade_cols) {
    col <- find_col(col_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Process district-level enrollment data
#'
#' @param df Raw district data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_enr <- function(df, end_year) {

  # Handle empty data
  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_result(end_year, "District"))
  }

  cols <- names(df)
  n_rows <- nrow(df)
  col_map <- get_mde_column_map()

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # IDs
  district_col <- find_col(col_map$district_id)
  if (!is.null(district_col)) {
    result$district_id <- as.character(trimws(df[[district_col]]))
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  # School/Campus ID is NA for district rows
  result$school_id <- rep(NA_character_, n_rows)
  result$campus_id <- rep(NA_character_, n_rows)

  # Names
  district_name_col <- find_col(col_map$district_name)
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(df[[district_name_col]])
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  result$school_name <- rep(NA_character_, n_rows)
  result$campus_name <- rep(NA_character_, n_rows)

  # Total enrollment
  total_col <- find_col(col_map$total)
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    result$row_total <- rep(NA_integer_, n_rows)
  }

  # Demographics
  demo_cols <- c("white", "black", "hispanic", "asian",
                 "native_american", "pacific_islander", "multiracial")

  for (name in demo_cols) {
    col <- find_col(col_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Gender
  male_col <- find_col(col_map$male)
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(col_map$female)
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Special populations
  special_cols <- c("econ_disadv", "lep", "special_ed")

  for (name in special_cols) {
    col <- find_col(col_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_cols <- c("grade_pk", "grade_k",
                  "grade_01", "grade_02", "grade_03", "grade_04",
                  "grade_05", "grade_06", "grade_07", "grade_08",
                  "grade_09", "grade_10", "grade_11", "grade_12")

  for (name in grade_cols) {
    col <- find_col(col_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Create state-level aggregate from district data
#'
#' @param district_df Processed district data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, end_year) {

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    school_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    school_name = NA_character_,
    campus_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    if (col %in% names(district_df)) {
      state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
    }
  }

  state_row
}


#' Create empty result data frame
#'
#' @param end_year School year end
#' @param type Entity type ("State", "District", or "School")
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_result <- function(end_year, type) {
  data.frame(
    end_year = integer(0),
    type = character(0),
    district_id = character(0),
    school_id = character(0),
    campus_id = character(0),
    district_name = character(0),
    school_name = character(0),
    campus_name = character(0),
    row_total = integer(0),
    stringsAsFactors = FALSE
  )
}
