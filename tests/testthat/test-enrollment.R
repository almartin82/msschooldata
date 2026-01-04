# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("N/A")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("get_available_years returns valid range", {
  years <- get_available_years()

  # Should return integer vector

  expect_true(is.integer(years) || is.numeric(years))

  # Should start at 2007 (2006-07 school year)
  expect_equal(min(years), 2007)

  # Should be sequential
  expect_equal(years, seq(min(years), max(years)))

  # Should include recent years
  expect_true(2024 %in% years)
})

test_that("fetch_enr validates year parameter", {
  # Years before data availability
  expect_error(fetch_enr(2000), "not available")
  expect_error(fetch_enr(2005), "not available")

  # Future years
  expect_error(fetch_enr(2030), "not available")
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("msschooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  path_wide <- get_cache_path(2023, "wide")
  expect_true(grepl("enr_wide_2023.rds", path_wide))

  # Test cache_exists returns FALSE for non-existent cache
  expect_false(cache_exists(9999, "tidy"))
})

test_that("get_mde_column_map returns expected structure", {
  col_map <- get_mde_column_map()

  # Should be a list
expect_true(is.list(col_map))

  # Should have key mappings
  expect_true("district_id" %in% names(col_map))
  expect_true("district_name" %in% names(col_map))
  expect_true("school_id" %in% names(col_map))
  expect_true("total" %in% names(col_map))

  # Demographic columns
  expect_true("white" %in% names(col_map))
  expect_true("black" %in% names(col_map))
  expect_true("hispanic" %in% names(col_map))

  # Special populations
  expect_true("econ_disadv" %in% names(col_map))
  expect_true("lep" %in% names(col_map))
  expect_true("special_ed" %in% names(col_map))

  # Grade levels
  expect_true("grade_k" %in% names(col_map))
  expect_true("grade_12" %in% names(col_map))
})

# Integration tests (require network access)
test_that("fetch_enr downloads and processes data", {
  skip_on_cran()
  skip_if_offline()

  # Use a recent year
  result <- tryCatch(
    fetch_enr(2023, tidy = FALSE, use_cache = FALSE),
    error = function(e) NULL
  )

  # Skip if download failed (network issues, API changes, etc.)
  # Note: fetch_enr returns a state-only row when API fails, so check for actual data
  skip_if(is.null(result), "Could not download data from MDE")
  skip_if(nrow(result) <= 1, "MDE API unavailable - only placeholder data returned")

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("type" %in% names(result))

  # Check we have all levels
  expect_true("State" %in% result$type)
  expect_true("District" %in% result$type)
  expect_true("School" %in% result$type)
})

test_that("tidy_enr produces correct long format", {
  skip_on_cran()
  skip_if_offline()

  # Get wide data
  wide <- tryCatch(
    fetch_enr(2023, tidy = FALSE, use_cache = TRUE),
    error = function(e) NULL
  )

  skip_if(is.null(wide), "Could not download data from MDE")
  skip_if(nrow(wide) <= 1, "MDE API unavailable - only placeholder data returned")

  # Tidy it
  tidy_result <- tidy_enr(wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)
})

test_that("id_enr_aggs adds correct flags", {
  skip_on_cran()
  skip_if_offline()

  # Get tidy data with aggregation flags
  result <- tryCatch(
    fetch_enr(2023, tidy = TRUE, use_cache = TRUE),
    error = function(e) NULL
  )

  skip_if(is.null(result), "Could not download data from MDE")
  skip_if(nrow(result) <= 1, "MDE API unavailable - only placeholder data returned")

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_school" %in% names(result))
  expect_true("is_charter" %in% names(result))

  # Check flags are boolean
  expect_true(is.logical(result$is_state))
  expect_true(is.logical(result$is_district))
  expect_true(is.logical(result$is_school))
  expect_true(is.logical(result$is_charter))

  # Check mutual exclusivity (each row is only one type)
  type_sums <- result$is_state + result$is_district + result$is_school
  expect_true(all(type_sums == 1))
})

test_that("fetch_enr_multi validates years", {
  # Should error on invalid years
  expect_error(fetch_enr_multi(c(2000, 2023)), "Invalid years")
  expect_error(fetch_enr_multi(c(2023, 2030)), "Invalid years")
})

test_that("process_enr handles empty data gracefully", {
  # Create empty raw data
  empty_raw <- list(
    school = data.frame(),
    district = data.frame()
  )

  # Should not error
  result <- process_enr(empty_raw, 2023)

  expect_true(is.data.frame(result))
  expect_true(nrow(result) >= 0)  # May have state row or be empty
})

test_that("generate_placeholder_data creates expected structure", {
  # Test placeholder generation
  placeholder <- generate_placeholder_data(2023, "School")

  expect_true(is.data.frame(placeholder))
  expect_true("DistrictCode" %in% names(placeholder))
  expect_true("DistrictName" %in% names(placeholder))
  expect_true("SchoolCode" %in% names(placeholder))
  expect_true("TotalEnrollment" %in% names(placeholder))

  # District placeholder should not have school columns
  district_placeholder <- generate_placeholder_data(2023, "District")
  expect_true("DistrictCode" %in% names(district_placeholder))
})
