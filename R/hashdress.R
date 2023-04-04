#' expand addresses using postal
#'
#' The DeGAUSS [`postal`](https://degauss.org/postal/) container is used
#' to expand a vector of addresses based on abbreviations.
#' Each call to DeGAUSS is cached to disk (`data-raw` folder in working directory),
#' making repetative function calls on the same data nearly instant.
#' @param addresses a vector of address strings
#' @param quiet suppress DeGAUSS output inside of R?
#' @return a list the same length as the input `addresses` where each
#' element is a vector of expanded addresses
#' @export
expand_addresses <- function(addresses, quiet = TRUE) {

  degauss_postal_version <- "0.1.4"
  # set cache for degauss_run
  fc <- memoise::cache_filesystem(fs::path(fs::path_wd(), "degauss_cache"))
  degauss_run <- memoise::memoise(dht::degauss_run, cache = fc, omit_args = "quiet")

  d_in <-
    tibble::tibble(address = addresses) |>
    dplyr::mutate(.id = dplyr::row_number())

  message("expanding addresses...")
  d_expand <-
    d_in |>
    degauss_run("postal", degauss_postal_version, "expand", quiet = quiet)

  d_out <-
    d_expand |>
    dplyr::select(.id, expanded_addresses) |>
    dplyr::group_by(.id) |>
    dplyr::summarize(expansions = list(c(expanded_addresses))) |>
    dplyr::pull(expansions)

  return(d_out)
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
  purrr::map(.x, ~ purrr::map_chr(., digest::digest, algo = "spookyhash"))
}

#' Add CAGIS Parcel ID
#'
#' The hashdress() function is used to add a set of hashdresses for
#' the parsed house_number and road from each input address in `.x$address`.
#' The hashdresses are compared to the
#' set of hashdresses in `cagis_hashdresses` for matches.
#' @details  One address can be linked to more than one parcel (e.g.,
#' "323 Fifth" on https://wedge3.hcauditor.org/search_results). Note that
#' this matches does not utilize the ZIP code, and instead assumes any input
#' address in located in Hamilton County, OH. If addresses are not screened for
#' ZIP codes (e.g., `cincy::zcta_tigris_2020`), then false positives are possible.
#' @param .x tibble/data.frame with a column containing addresses, called "address"
#' @param quiet logical; suppress intermediate DeGAUSS console output?
#' @return .x with additional parcel_id column; this will be a list-col because more than
#' one parcel can be matched to a given address
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
## add_parcel_id <- function(.x, quiet = TRUE) {
##   d <- hashdress(.x,
##     address_stub_components = c("parsed.house_number", "parsed.road"),
##     quiet = quiet
##   )
##   d$parcel <- purrr::map(d$hashdresses, ~ cagis_hashdresses[., parcel_id])
##   d |>
##     dplyr::rowwise() |>
##     dplyr::mutate(parcel_id = list(unique(as.character(parcel)))) |>
##     dplyr::select(-expanded_addresses, -hashdresses, -parcel)
## }
