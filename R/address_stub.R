#' extract the street number and name (i.e., "address stub") from address text
#'
#' Input addresses are cleaned (convert to lowercase, remove
#' non-alphanumeric characters and excess whitespace) and then
#' tagged into components. The `street_number` and `street_name`
#' components are pasted together to create the address stub.
#' If either the street_number or street_name are missing
#' then the address_stub will be returned as missing.
#' If `filter_zip` is TRUE, then addresses without a parsed
#' 5-digit ZIP code in Hamilton County will have a missing address stub.
#' @param .x a vector of address character strings
#' @param filter_zip force addresses with non-Hamilton ZIP codes to have a missing address_stub?
#' (i.e., `cincy::zcta_tigris_2020$zcta_2020`)
#' @return a vector of cleaned address stubs (street_number + street_name)
#' @export
create_address_stub <- function(.x, filter_zip = TRUE) {

  clean_addresses <-
    .x |>
    stringr::str_replace_all(stringr::fixed("\\"), "") |>
    stringr::str_replace_all(stringr::fixed("\""), "") |>
    stringr::str_replace_all("[^a-zA-Z0-9-]", " ") |>
    stringr::str_squish() |>
    tolower()

  tagged_addresses <-
    purrr::map(clean_addresses, tag_address, .progress = "tagging addresses") |>
    purrr::list_rbind()

  address_stubs <-
    tagged_addresses |>
    tidyr::unite("address_stub", c(street_number, street_name), sep = " ", na.rm = TRUE, remove = FALSE)

  address_stubs[is.na(address_stubs$street_number), "address_stub"] <- NA
  address_stubs[is.na(address_stubs$street_name), "address_stub"] <- NA
  if (filter_zip) {
    address_stubs[!address_stubs$zip_code %in% cincy::zcta_tigris_2020$zcta_2020, "address_stub"] <- NA
  }

  return(address_stubs$address_stub)
}
