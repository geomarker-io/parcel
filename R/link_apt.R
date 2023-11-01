#' Link one address to parcel pseudo-identifiers for apartment complexes
#'
#' To match a parcel to an apartment complex pseudo-identifier, it must contain:  
#' - a Hamilton County ZIP code
#' - a street name matching the street names in `parcel:::apt_defs`
#' - a street number within the ranges for each pseudo-identifier in `parcel:::apt_defs`
#'
#' @param x a single address character string
#' @return apt pseudo-identifier character string; `NA` if not matched
link_apt <- function(x) {
  x_tags <- tag_address(x)
  if (!x_tags$zip_code %in% cincy::zcta_tigris_2020$zcta_2020) {
    return(NA)
  }
  apt_id <-
    purrr::map(apt_defs, purrr::pluck, "street_name") |>
    purrr::map_lgl(\(x) x_tags[["street_name"]] %in% x) |>
    which() |>
    names()
  if(length(apt_id) == 0) return(NA)
  if (x_tags$street_number < apt_defs[[apt_id]]$range_low) return(NA)
  if (x_tags$street_number > apt_defs[[apt_id]]$range_high) return(NA)
  return(apt_id)
}

apt_defs <-
  list(
    "president" =
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
      ),
    "bahama" =
      list(
        street_name = c("bahama terrace", "bahama te", "bahama ter"),
        range_low = 5000,
        range_high = 5999
      ),
    "hawaiian" =
      list(
        street_name = c("hawaiian terrace", "hawaiian te", "hawaiian ter"),
        range_low = 4000,
        range_high = 5999
      ),
    "dewdrop" =
      list(
        street_name = c("dewdrop circle"),
        range_low = 400,
        range_high = 599
      ),
    "winneste" =
      list(
        street_name = c("winneste avenue", "winneste ave", "winneste av"),
        range_low = 4000,
        range_high = 5999
      ),
    "walden_glen" =
      list(street_name = c("walden glen circle"),
           range_low = 2000,
           range_high = 2999
           ),
    "clovernook" =
      list(street_name = c("clovernook avenue", "clovernook ave", "clovernook av"),
           range_low = 7000,
           range_high = 7999
           )
  )
