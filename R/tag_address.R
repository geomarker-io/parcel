#' clean address text
#'
#' convert to lowercase, remove non-alphanumeric characters and excess whitespace
#' (adapted from degauss-org/dht::clean_address)
#' @param .x a vector of address character strings
#' @return a vector of cleaned addresses
#' @export
clean_address <- function(.x) {
  .x |>
    stringr::str_replace_all(stringr::fixed("\\"), "") |>
    stringr::str_replace_all(stringr::fixed("\""), "") |>
    stringr::str_replace_all("[^a-zA-Z0-9-]", " ") |>
    stringr::str_squish() |>
    tolower()
}

#' tag components of an address
#'
#' This function relies on `usaddress` python library https://usaddress.readthedocs.io/en/latest/
#' It can be installed to a python virtual environment specific to R with:
#' `py_install("usaddress", pip = TRUE)` (See the README for more details on installing
#' and managing non-system installations of python with {reticulate}.
#'
#' This function uses a custom tag mapping to combine address components into the columns in the returned tibble
#' (see https://usaddress.readthedocs.io/en/latest/#details for full definition of components):
#'
#' - `street_number`: `AddressNumber`, `AddressNumberPrefix`, `AddressNumberSuffix`
#' - `street_name`: `StreetName`, `StreetNamePreDirectional`, `StreetNamePostDirectional`, `StreetNamePostModifier`, `StreetNamePostType`
#' - `city`: `PlaceName`
#' - `state`: `StateName`
#' - `zip`: the **first five characters** of `ZipCode`
#'
#' If an address is not classified as a `Street Address` (i.e. `Intersection`, `PO Box`, or `Ambiguous`),
#' then the columns in the returned component tibble will all be missing.
#' @param address a character string that is a United States mailing address
#' @param clean clean addresses with `clean_address()` prior to tagging?
#' @return a tibble with `street_number`, `street_name`, `city`, `state`, and `zip_code` columns
#' @export
tag_address <- function(address, clean = TRUE) {
  out_template <-
    tibble::tibble(
      "street_number" = NA,
      "street_name" = NA,
      "city" = NA,
      "state" = NA,
      "zip_code" = NA
    )
  if (clean) address <- clean_address(address)
  safe_tag <- purrr::possibly(usaddress$tag, otherwise = list(out_template, "repeated_label_error"))
  tags <-
    safe_tag(address,
      tag_mapping =
        list(
          "Recipient" = "name",
          "AddressNumber" = "street_number",
          "AddressNumberPrefix" = "street_number",
          "AddressNumberSuffix" = "street_number",
          "StreetName" = "street_name",
          "StreetNamePreDirectional" = "street_name",
          "StreetNamePreModifier" = "street_name",
          "StreetNamePreType" = "street_name",
          "StreetNamePostDirectional" = "street_name",
          "StreetNamePostModifier" = "street_name",
          "StreetNamePostType" = "street_name",
          "CornerOf" = "corner",
          "IntersectionSeparator" = "corner",
          "LandmarkName" = "place",
          "USPSBoxGroupID" = "address1",
          "USPSBoxGroupType" = "address1",
          "USPSBoxID" = "address1",
          "USPSBoxType" = "address1",
          "BuildingName" = "place",
          "OccupancyType" = "address2",
          "OccupancyIdentifier" = "address2",
          "SubaddressIdentifier" = "address2",
          "SubaddressType" = "address2",
          "PlaceName" = "city",
          "StateName" = "state",
          "ZipCode" = "zip_code"
        )
    )
  if (!tags[[2]] == "Street Address") {
    return(out_template)
  }
  out <-
    tibble::tibble(
      "street_number" = purrr::pluck(tags[[1]], "street_number"),
      "street_name" = purrr::pluck(tags[[1]], "street_name"),
      "city" = purrr::pluck(tags[[1]], "city"),
      "state" = purrr::pluck(tags[[1]], "state"),
      "zip_code" = purrr::pluck(tags[[1]], "zip_code")
    )
  if (any(nchar(out$zip_code) > 5)) out$zip_code <- substr(out$zip_code, 1, 5)
  return(out)
}
