#' 'expand' and hash addresses
#'
#' The DeGAUSS [`postal`](https://degauss.org/postal/) container is used
#' to expand addresses based on abbreviations.
#' Because each input address will likely result in more than one expanded address,
#' the newly added `expanded_addresses` column is a list-col.
#' Each `expanded_address` is hashed using the 'spookyhash' algorithm and also
#' returned as a list col. These combinations of hashes for all expanded address
#' (i.e. "hashdress") can be used to link to other addresses hashdressed
#' using the same version of this package.
#'
#' Any input address for which at least one of the `address_stub_components` cannot be found
#' will result in a missing `stub_address` and it will not be expanded nor hashed.
#'
#' Each call to DeGAUSS is cached to disk (`data-raw` folder in working directory),
#' making repetative function calls on the same data nearly instant.
#' @param .x a tibble containing an `address` column
#' @param address_stub_components a vector of character strings of parsed address
#' components to use to construct the address stub used for expansion and hashing
#' @param quiet logical; suppress intermediate DeGAUSS console output?
#' @return `.x` with newly added columns
#' - `address_stub` is the parsed and cleaned address used for expansion
#' - `expanded_addresses` are the expanded addresses (a list-col)
#' - `hashdresses` are the hashdresses for each of the expanded addresses
#' @export
#' @examples
#' \dontrun{
#' d <-
#'   tibble::tibble(address = c(
#'     "224 Woolper Ave Cincinnati OH 45220",
#'     "222 East Central Parkway Cincinnati OH 45220",
#'     "352 Helen St Cincinnati OH 45202",
#'     "5377 Bahama Ter Apt 1 Cincinnati Ohio 45223",
#'     "5377 Bahama Te Apt 1 Cincinnati Ohio 45223",
#'     "1851 Campbell Dr Hamilton Ohio 45011",
#'     "2 Maplewood Dr Ryland Heights, KY 41015"
#'   ))
#' hashdress(d)
#' }
hashdress <- function(.x,
                      address_stub_components = c(
                        "parsed.house_number",
                        "parsed.road",
                        "parsed.postcode_five"
                      ),
                      quiet = TRUE) {
  degauss_postal_version <- "0.1.4"

  # set cache for degauss_run
  fc <- memoise::cache_filesystem(fs::path(fs::path_wd(), "degauss_cache"))
  degauss_run <- memoise::memoise(dht::degauss_run, cache = fc, omit_args = "quiet")

  d_in <- .x |> dplyr::mutate(.id = dplyr::row_number())

  message("parsing addresses...")
  d_stub <-
    d_in |>
    dplyr::select(.id, address) |>
    dplyr::distinct() |>
    degauss_run("postal", degauss_postal_version, quiet = quiet) |>
    # if there are NA in any of the "address_stub_components", then don't create partial address_stub
    dplyr::select(c(.id, tidyselect::any_of(address_stub_components))) |>
    stats::na.omit() |>
    tidyr::unite(
      col = "address_stub",
      tidyselect::any_of(address_stub_components),
      sep = " "
    ) |>
    dplyr::rename(address = address_stub)

  message("expanding addresses...")
  d_expand <-
    d_stub |>
    degauss_run("postal", degauss_postal_version, "expand", quiet = quiet) |>
    dplyr::select(.id, address_stub = address, expanded_addresses) |>
    dplyr::group_by(.id, address_stub) |>
    dplyr::summarize(expanded_addresses = list(expanded_addresses), .groups = "drop")

  d_expand <-
    d_expand |>
    dplyr::rowwise() |>
    dplyr::mutate(
      hashdresses = list(purrr::map_chr(expanded_addresses,
        digest::digest,
        algo = "spookyhash"
      ))
    ) |>
    dplyr::ungroup()

  d_out <- dplyr::left_join(d_in, d_expand, by = ".id") |> dplyr::select(-.id)
  return(d_out)
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
add_parcel_id <- function(.x, quiet = TRUE) {
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
