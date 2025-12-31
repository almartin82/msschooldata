#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

#' msschooldata: Fetch and Process Mississippi School Data
#'
#' The msschooldata package provides functions for downloading, processing,
#' and analyzing school enrollment data from the Mississippi Department of
#' Education (MDE). Data is sourced from the MDE reporting system at
#' newreports.mdek12.org.
#'
#' @section Data Source:
#' Mississippi Department of Education (MDE) provides enrollment data through
#' their public reporting portal. Data is collected via the Mississippi Student
#' Information System (MSIS) and reflects enrollment counts as of October 1
#' of each school year.
#'
#' @section Available Data:
#' \itemize{
#'   \item Years: 2007 to present (2006-07 school year onwards)
#'   \item Aggregation levels: State, District, School
#'   \item Demographics: Race/ethnicity (7 categories), gender
#'   \item Special populations: Economically disadvantaged, LEP, Special Education
#'   \item Grade levels: PK through 12
#' }
#'
#' @section Main Functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Download enrollment data for a single year}
#'   \item{\code{\link{fetch_enr_multi}}}{Download enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide format to long/tidy format}
#'   \item{\code{\link{get_available_years}}}{List available data years}
#' }
#'
#' @section Caching:
#' Downloaded data is cached locally to avoid repeated downloads. Use
#' \code{\link{cache_status}} to see cached files and \code{\link{clear_cache}}
#' to remove them.
#'
#' @docType package
#' @name msschooldata-package
#' @aliases msschooldata
NULL
