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
link_parcel <- function(x, threshold = 0.2) {
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

  data_ref <- readRDS(fs::path_package("parcel", "parcel_address_stubs.rds"))

  inst_addr <- readr::read_csv(fs::path_package("parcel", "known_nonresidential_stubs.csv"), col_types = "cc")

  inst_addr <-
    purrr::map(1:nrow(inst_addr), \(.) list(
      address = inst_addr$address_stub[.])) |>
    rlang::set_names(inst_addr$parcel_id)

  data_ref <- append(data_ref, inst_addr)

  links <-
    gaz$join(data_1 = data_in,
             data_2 = data_ref,
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
