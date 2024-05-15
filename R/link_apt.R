#' Link one address to parcel pseudo-identifiers for apartment complexes
#'
#' To match a parcel to an apartment complex pseudo-identifier, it must contain:
#' - a Hamilton County ZIP code
#' - a street name matching the street names in `parcel:::apt_defs`
#' - a street number within the ranges for each pseudo-identifier in `parcel:::apt_defs`
#'
#' @param x a single address character string
#' @return apt pseudo-identifier character string; `NA` if not matched
#' @export
link_apt <- function(x) {
  x_tags <- tag_address(x)
  if (!x_tags$zip_code %in% cincy::zcta_tigris_2020$zcta_2020) {
    return(NA)
  }
  apt_id <-
    purrr::map(apt_defs, purrr::pluck, "street_name") |>
    purrr::map_lgl(\(x) purrr::pluck(x_tags, "street_name", .default = NA) %in% x) |>
    which() |>
    names()
  if (length(apt_id) == 0) {
    return(NA)
  }
  if (x_tags$street_number < apt_defs[[apt_id]]$range_low) {
    return(NA)
  }
  if (x_tags$street_number > apt_defs[[apt_id]]$range_high) {
    return(NA)
  }
  return(apt_id)
}

apt_defs <-
  list(
    "villages_at_roll_hill" =
      list(
        street_name = paste("president", c("drive", "dr")),
        range_low = 3000,
        range_high = 4999
      ),
    "villages_at_roll_hill" =
      list(
        street_name = paste("nottingham", c("road", "rd", "drive", "dr")),
        range_low = 2000,
        range_high = 2999
      ),
    "villages_at_roll_hill" =
      list(
        street_name = paste("williamsburg", c("drive", "dr")),
        range_low = 2200,
        range_high = 2599
      ),
    "tower" =
      list(
        street_name = c(paste("east tower", c("drive", "dr")), paste("e tower", c("drive", "dr"))),
        range_low = 2000,
        range_high = 2999
      ),
    "bahama" =
      list(
        street_name = paste("bahama", c("terrace", "te", "ter", "terr")),
        range_low = 5000,
        range_high = 5999
      ),
    "hawaiian" =
      list(
        street_name = paste("hawaiian", c("terrace", "te", "ter", "terr")),
        range_low = 4000,
        range_high = 5999
      ),
    "dewdrop" =
      list(
        street_name = paste("dewdrop", c("circle", "cir")),
        range_low = 400,
        range_high = 599
      ),
    "winton_terrace" =
      list(
        street_name = paste("winneste", c("avenue", "ave", "av")),
        range_low = 4800,
        range_high = 5099
      ),
    "winton_terrace" =
      list(
        street_name = paste("este", c("avenue", "ave", "av")),
        range_low = 4700,
        range_high = 4899
      ),
    "winton_terrace" =
      list(
        street_name = paste("kings run", c("drive", "dr")),
        range_low = 400,
        range_high = 519
      ),
    "winton_terrace" =
      list(
        street_name = paste("kings run", c("court", "ct")),
        range_low = 1,
        range_high = 69
      ),
    "winton_terrace" =
      list(
        street_name = paste("craft", c("street", "st")),
        range_low = 1,
        range_high = 299
      ),
    "winton_terrace" =
      list(
        street_name = paste("topridge", c("place", "pl")),
        range_low = 1,
        range_high = 899
      ),
    "silver_oak" =
      list(
        street_name = paste("winneste", c("avenue", "ave", "av")),
        range_low = 5600,
        range_high = 5799
      ),
    "silver_oak" =
      list(
        street_name = paste("winneste", c("court", "ct")),
        range_low = 600,
        range_high = 699
      ),
    "silver_oak" =
      list(
        street_name = paste("gardenview", c("lane", "ln")),
        range_low = 5400,
        range_high = 5499
      ),
    "silver_oak" =
      list(
        street_name = paste("gardenhill", c("lane", "ln")),
        range_low = 5500,
        range_high = 5799
      ),
    "silver_oak" =
      list(
        street_name = paste("wintonview", c("place", "pl")),
        range_low = 5400,
        range_high = 5499
      ),
    "winton_hills_mha" =
      list(
        street_name = paste("winneste", c("avenue", "ave", "av")),
        range_low = 5300,
        range_high = 5499
      ),
    "winton_hills_mha" =
      list(
        street_name = paste("strand", c("lane", "ln")),
        range_low = 580,
        range_high = 689
      ),
    "winton_hills_mha" =
      list(
        street_name = paste("holland", c("drive", "dr")),
        range_low = 5100,
        range_high = 5499
      ),
    "winton_hills_mha" =
      list(
        street_name = paste("vivian", c("place", "pl")),
        range_low = 5200,
        range_high = 5299
      ),
    "winton_hills_mha" =
      list(
        street_name = paste("vassar", c("court", "ct")),
        range_low = 500,
        range_high = 699
      ),
    "winton_hills_mha" =
      list(
        street_name = paste("bettman", c("drive", "dr")),
        range_low = 5300,
        range_high = 5499
      ),
    "winton_hills_mha" =
      list(
        street_name = paste("dutch colony", c("drive", "dr")),
        range_low = 500,
        range_high = 899
      ),
    "winton_hills_mha" =
      list(
        street_name = paste("hebron", c("court", "ct")),
        range_low = 5400,
        range_high = 5499
      ),
    "walden_glen" =
      list(
        street_name = paste("walden glen", c("circle", "cir")),
        range_low = 2000,
        range_high = 2999
      ),
    "clovernook" =
      list(
        street_name = paste("clovernook", c("avenue", "ave", "av")),
        range_low = 7600,
        range_high = 7999
      )
  )
