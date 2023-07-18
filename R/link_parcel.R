#' @importFrom reticulate %as%
#' @export
reticulate::`%as%`

#' link addresses to CAGIS parcel identifiers
#'
#' This function uses the trained dedupe model included with the package
#' to link one or more parcel identifiers to a vector of input
#' addresses.
#'
#' Note that one address can be linked to more than one parcel (e.g.,
#' "323 Fifth" on https://wedge3.hcauditor.org/search_results). In this case,
#' the input address will have multiple rows, one for each of the multiple matches.
#' @param x a vector of address character strings
#' @param threshold potential matches will only be returned if their `score` exceeds this value (from 0 to 1) 
#' @return a tibble with a column of *unique*, matched addresses input as `x` along
#' with columns for their `parcel_id`(s) and matching `score`(s) (use this as a lookup
#' table for assigning parcel_id in other workflows, making decisions about what to do
#' with multiple matches and matching thresholds, etc.)
#' @export
link_parcel <- function(x, threshold = 0.5) {
  with(py$open(fs::path(fs::path_package("parcel"), "learned_settings"), "rb") %as% f, {
    gaz <<- dedupe$StaticRecordLink(f)
  })

  input_data <-
    tibble::tibble(input_address = x) |>
    dplyr::mutate(input_address_stub = create_address_stub(input_address, filter_zip = TRUE))

  # remove non-Hamilton address stubs
  input_data_for_link <- stats::na.omit(input_data)

  data_in <-
    purrr::map(1:nrow(input_data_for_link), \(.) list(
      address = input_data_for_link$input_address_stub[.])) |>
    rlang::set_names(input_data_for_link$input_address)

  links <-
    gaz$join(data_1 = data_in,
             data_2 = readRDS(fs::path_package("parcel", "parcel_address_stubs.rds")),
             threshold = threshold,
             constraint = "many-to-many")

  np <- reticulate::import("numpy", convert = FALSE)
  alinks <- np$array(links)
  pairs <-
    alinks[["pairs"]] |>
    reticulate::py_to_r() |>
    as.vector()

  out <-
    tibble::tibble(input_address = pairs[seq_along(pairs) %% 2 > 0],
                   parcel_id = pairs[seq_along(pairs) %% 2 == 0],
                   score = as.numeric(reticulate::py_to_r(alinks[["score"]])))

  return(out)
}

#' return parcel data for input addresses
#'
#' This helper function produces a tibble of parcel data for an input vector of addresses.
#' The `link_parcel()` function returns all possible matches above the `threshold` for each
#' input address and this function chooses the single best match based on the maximum score.
#' Note that one address can be linked to more than one parcel with the same match score (e.g.,
#' "323 Fifth" on https://wedge3.hcauditor.org/search_results). In this case,
#' a special identifier, `TIED_MATCHES` is returned instead of a missing `parcel_id`.
#' For finer control of selecting matched parcels based on scores, use `link_parcel()`
#' @param x a vector of address character strings
#' @return a tibble with the `input_address`es defined in `x` in the first column,
#' and columns corresponding to matched parcel characteristics
#' @export
get_parcel_data <- function(x) {

  parcel_links <- link_parcel(x)

  tied_high_scores_addresses <-
    parcel_links |>
    dplyr::group_by(input_address) |>
    dplyr::mutate(high_score = max(score)) |>
    dplyr::filter(sum(high_score == score) > 1) |>
    dplyr::pull(input_address) |>
    unique()

  parcel_links[parcel_links$input_address %in% tied_high_scores_addresses, "parcel_id"] <- "TIED_MATCHES"

  parcel_matches <-
    parcel_links |>
    dplyr::group_by(input_address) |>
    dplyr::arrange(dplyr::desc(score), .by_group = TRUE) |>
    dplyr::slice(1)
  
  d_parcel <- 
    fs::path_package("parcel", "cagis_parcels") |>
    codec::read_tdr_csv()

  tibble::tibble(input_address = x) |>
    dplyr::left_join(parcel_matches, by = dplyr::join_by(input_address)) |>
    dplyr::left_join(d_parcel, by = dplyr::join_by(parcel_id), relationship = "many-to-one")
  }
