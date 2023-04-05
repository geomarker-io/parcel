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
