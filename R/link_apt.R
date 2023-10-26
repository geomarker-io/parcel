#' Link one addresses to custom parcel identifiers based on street names and ranges
#'
#' This function will probably take a long time to map over large numbers of addresses.
#' Reduce the use of this function by only applying it to addresses that are unmatched
#' with `link_parcel()`, but have a Cincinnati ZIP code. (
#' @param x a vector of address character strings
link_apt <- function(x) {
  x_tags <- tag_address(x)
  if (!x_tags$zip_code %in% cincy::zcta_tigris_2020$zcta_2020) {
    warning("At least one non-Cincinnati ZIP code found; returning NA")
    return(NA)
  }
  x_tags$street_name %in% purrr::map(apt_defs, purrr::pluck, "street_name")
  out <-
    purrr::map(apt_defs, purrr::pluck, "street_name") |>
    purrr::map(\(x) x_tags[["street_name"]] %in% x) |>
    unlist() |>
    which() |>
    names()
  if (length(out) == 0) out <- NA
  return(out)
}

apt_defs <-
  list(
    "fay" =
      list(
        street_name = c("president drive", "president dr"),
        range_low = 3000,
        range_high = 3999
      ),
    "tower" =
      list(
        street_name = c("east tower drive", "e tower drive", "east tower dr", "e tower dr"),
        range_low = 2000,
        range_high = 29999
      )
  )
