# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL


#' Convert to numeric, handling suppression markers
#'
#' MDE uses various markers for suppressed data (*, <, N/A, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "null", "NULL")] <- NA_character_

  # Handle any remaining non-numeric values
  suppressWarnings(as.numeric(x))
}


#' Get list of available years
#'
#' Returns the range of school years for which Mississippi enrollment
#' data is available.
#'
#' @return Integer vector of available end years
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  # Mississippi MDE data is available from 2006-2007 school year to present

  # Data Explorer shows data from 2006 onwards
  # As of late 2024, data through 2023-24 school year is available
  2007:2025
}
