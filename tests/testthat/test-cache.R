# Tests for caching functions

test_that("get_cache_dir creates directory", {
  cache_dir <- get_cache_dir()

  # Should return a path
  expect_true(is.character(cache_dir))
  expect_true(nchar(cache_dir) > 0)

  # Directory should exist (function creates it)
  expect_true(dir.exists(cache_dir))

  # Path should include package name
  expect_true(grepl("msschooldata", cache_dir))
})

test_that("get_cache_path generates correct filenames", {
  # Tidy format
  path_tidy <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024\\.rds$", path_tidy))

  # Wide format
  path_wide <- get_cache_path(2023, "wide")
  expect_true(grepl("enr_wide_2023\\.rds$", path_wide))

  # Different years
  path_old <- get_cache_path(2010, "tidy")
  expect_true(grepl("enr_tidy_2010\\.rds$", path_old))
})

test_that("cache_exists works correctly", {
  # Non-existent year should return FALSE
  expect_false(cache_exists(9999, "tidy"))
  expect_false(cache_exists(9999, "wide"))

  # Create a test cache file
  test_df <- data.frame(x = 1:5)
  test_path <- get_cache_path(8888, "test")

  # Ensure directory exists
  cache_dir <- get_cache_dir()

  # Save test file
  saveRDS(test_df, test_path)

  # Should exist now
  expect_true(file.exists(test_path))

  # Clean up
  unlink(test_path)
  expect_false(file.exists(test_path))
})

test_that("write_cache and read_cache roundtrip works", {
  # Create test data
  test_df <- data.frame(
    end_year = 2024,
    district_id = "0001",
    enrollment = 1000
  )

  # Use a test year that won't conflict
  test_year <- 7777

  # Write to cache
  write_cache(test_df, test_year, "test")

  # Read back
  retrieved <- read_cache(test_year, "test")

  # Should be identical
  expect_equal(test_df$end_year, retrieved$end_year)
  expect_equal(test_df$district_id, retrieved$district_id)
  expect_equal(test_df$enrollment, retrieved$enrollment)

  # Clean up
  test_path <- get_cache_path(test_year, "test")
  unlink(test_path)
})

test_that("clear_cache removes files", {
  # Create some test cache files
  test_df <- data.frame(x = 1)

  write_cache(test_df, 6666, "tidy")
  write_cache(test_df, 6666, "wide")
  write_cache(test_df, 6667, "tidy")

  # Verify files exist
  expect_true(file.exists(get_cache_path(6666, "tidy")))
  expect_true(file.exists(get_cache_path(6666, "wide")))
  expect_true(file.exists(get_cache_path(6667, "tidy")))

  # Clear specific year and type
  clear_cache(6666, "tidy")
  expect_false(file.exists(get_cache_path(6666, "tidy")))
  expect_true(file.exists(get_cache_path(6666, "wide")))  # Should still exist

  # Clear remaining test files
  clear_cache(6666)
  clear_cache(6667)

  expect_false(file.exists(get_cache_path(6666, "wide")))
  expect_false(file.exists(get_cache_path(6667, "tidy")))
})

test_that("cache_status returns expected structure", {
  # cache_status should return a data frame (even if empty)
  result <- cache_status()

  # When called with invisible, returns data frame
  expect_true(is.data.frame(result) || is.null(result))
})
