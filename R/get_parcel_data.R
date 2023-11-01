#' return parcel data for input addresses
#'
#' This helper function produces a tibble of parcel data for an input vector of addresses.
#' The `link_parcel()` function returns all possible matches above the `threshold` for each
#' input address and this function chooses the single best match based on the maximum score.
#' Note that one address can be linked to more than one parcel with the same match score (e.g.,
#' "323 Fifth" on https://wedge3.hcauditor.org/search_results). In this case,
#' a special identifier, `TIED_MATCHES` is returned instead of a missing `parcel_id`.
#' Addresses are subsequently tried to be matched with a known apartment
#' complex using `link_apt()`. (Matched apartment complex psuedo-identifers take precedence over
#' matched parcel identifers.)
#' The `hamilton_online_parcels` tabular data resource is also linked based on `parcel_id`.
#' For finer control of selecting matched parcels based on scores, use `link_parcel()` and `link_apt()`
#' @param x a vector of address character strings
#' @return a tibble with the `input_address`es defined in `x` in the first column,
#' and columns corresponding to matched parcel characteristics from CAGIS and Auditor Online Summary website
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

  x_parcels <-
    tibble::tibble(input_address = x) |>
    dplyr::left_join(parcel_matches, by = dplyr::join_by(input_address)) |>
    dplyr::rowwise() |>
    dplyr::mutate(apt_id = link_apt(input_address)) |>
    dplyr::mutate(parcel_id = dplyr::coalesce(apt_id, parcel_id)) |>
    dplyr::select(-apt_id)

  d_parcel <-
    fs::path_package("parcel", "cagis_parcels") |>
    codec::read_tdr_csv()

  d_online_parcel <-
    fs::path_package("parcel", "hamilton_online_parcels") |>
    codec::read_tdr_csv()

  x_parcels |>
    dplyr::left_join(d_parcel, by = dplyr::join_by(parcel_id), relationship = "many-to-one") |>
    dplyr::left_join(d_online_parcel, by = dplyr::join_by(parcel_id), relationship = "many-to-one")
}
