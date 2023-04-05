#' prepare addresses for matching to CAGIS Parcel data
#'
#' Input addresses are cleaned (convert to lowercase, remove
#' non-alphanumeric characters and excess whitespace) and then
#' tagged into components. The `street_number` and `street_name`
#' components are pasted together to create the address stub.
#' If either the street_number or street_name are missing *or*
#' the addresses does not have a parsed 5-digit ZIP code that is in
#' Hamilton County, then the address_stub will be returned as missing.
#' @param .x a vector of address character strings
#' @return a vector of cleaned address stubs (street_number + street_name)
create_address_stub <- function(.x) {

  clean_addresses <-
    .x |>
    stringr::str_replace_all(stringr::fixed("\\"), "") |>
    stringr::str_replace_all(stringr::fixed("\""), "") |>
    stringr::str_replace_all("[^a-zA-Z0-9-]", " ") |>
    stringr::str_squish() |>
    tolower()

  tagged_addresses <-
    purrr::map(clean_addresses, tag_address, .progress = "tagging addresses") |>
    purrr::list_rbind() |>
    dplyr::mutate(zip_code = substr(zip_code, 1, 5))

  address_stubs <-
    tagged_addresses |>
    tidyr::unite("address_stub", c(street_number, street_name), sep = " ", na.rm = TRUE, remove = FALSE)

  address_stubs[is.na(address_stubs$street_number), "address_stub"] <- NA
  address_stubs[is.na(address_stubs$street_name), "address_stub"] <- NA
  address_stubs[!address_stubs$zip_code %in% cincy::zcta_tigris_2020$zcta_2020, "address_stub"] <- NA

  return(address_stubs$address_stub)
}

#' hash addresses
#'
#' These combinations of hashes for all expanded address
#' (i.e. "hashdress") can be used to link to other addresses hashdressed
#' using the same version of this package.
#' @param .x a list of vectors of address character strings
#' @return a list the same length as .x
#' @export
hashdress <- function(.x) {
  purrr::map(.x, ~ purrr::map_chr(., digest::digest, algo = "spookyhash"), .progress = TRUE)
}

#' Add CAGIS Parcel ID using hashdress method
#'
#' A vector of address character strings are expanded and hashed
#' into a set of hashdresses to match to an internal lookup
#' table containing hashdresses for CAGIS Parcels.
#'
#' Addresses will be parsed and only the `street_number` and `street_name`
#' *from addresses with Hamilton County ZIP codes* are used to
#' expand, hashdress, and match to a parcel identifier. Addresses not in Hamilton
#' County will return a missing parcel identifier without an attempted match.
#' One address can be linked to more than one parcel (e.g.,
#' "323 Fifth" on https://wedge3.hcauditor.org/search_results). 
#' @param .x a vector of address character strings
#' @param quiet logical; suppress intermediate DeGAUSS console output?
#' @return a list the same length as .x; each item will be a vector of `parcel_id`s
#' because more than one parcel can be matched to a given address
#' @importFrom data.table data.table
#' @export
#' @examples
#' \dontrun{
#' d <- data.frame(address = c(
#'   "3937 Rose Hill Ave Cincinnati OH 45229",
#'   "424 Klotter Ave Cincinnati OH 45214",
#'   "3328 Bauerwoods Dr Cincinnati OH 45251"
#' ))
#' add_parcel_id(d, quiet = TRUE)
#' }
add_parcel_id <- function(.x, quiet = TRUE) {

  cagis_hashdresses <- readRDS(fs::path_package("parcel", "cagis_hashdresses.rds"))

  purrr::map(.x, tag_address, .progress = "tagging addresses") |>
    purrr::list_rbind() |>
    mutate(zip_code = substr(zip_code, 1, 5)) |>
    filter(zip_code %in% cincy::zcta_tigris_2020$zcta_2020)
  # create address stub; expand; hash
  # match to cagis_hashdresses

  d <- hashdress(.x,
    address_stub_components = c("parsed.house_number", "parsed.road"),
    quiet = quiet
  )
  d$parcel <- purrr::map(d$hashdresses, ~ cagis_hashdresses[., parcel_id])
  d |>
    dplyr::rowwise() |>
    dplyr::mutate(parcel_id = list(unique(as.character(parcel)))) |>
    dplyr::select(-expanded_addresses, -hashdresses, -parcel)
}
