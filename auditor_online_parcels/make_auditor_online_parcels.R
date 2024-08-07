#' scrape hamilton county auditor online summary data
#' This function downloads data from the auditor website, please be polite!
#' @param parcel_id numeric or character parcel identifier
#' @return named character vector
#' @examples
#' scrape_hamilton_parcel("2170054005900")
#' scrape_hamilton_parcel("5000341051800")
scrape_hamilton_parcel <- function(parcel_id) {
  haul <-
    glue::glue("https://wedge3.hcauditor.org/view/re/{parcel_id}/2022/summary") |>
    xml2::read_html() |>
    rvest::html_nodes("#property_overview_wrapper td") |>
    rvest::html_text()
  setNames(
    haul[seq(from = 2, to = length(haul), by = 2)],
    haul[seq(from = 1, to = length(haul), by = 2)]
  )
}

## # to run the very long process of scraping without using a prestored result, run:
## d <- readRDS("../cagis_parcels/cagis_parcels/cagis_parcels.rds")
## httr::set_config(httr::user_agent("Mozilla/5.0 (Windows NT 5.1; rv:52.0) Gecko/20100101 Firefox/52.0"))
## d$auditor_online <-
##   mappp::mappp(d$parcel_id, scrape_hamilton_parcel, parallel = FALSE, cache = TRUE, cache_name = "auditor_online_cache")
## # save dated copy of parcel scrape
## saveRDS(d, "./auditor_online_parcels/auditor_online_scrape_2024-01-16.rds")

d_scrape <- readRDS("auditor_online_parcels/auditor_online_scrape_2024-01-16.rds")

d_auditor_online_parcels <-
  d_scrape |>
  dplyr::select(parcel_id, auditor_online) |>
  dplyr::mutate(
    year_built = as.integer(purrr::map_chr(auditor_online, "Year Built")),
    n_total_rooms = as.integer(purrr::map_chr(auditor_online, "Total Rooms")),
    n_bedrooms = as.integer(purrr::map_chr(auditor_online, "# Bedrooms")),
    n_full_bathrooms = as.integer(purrr::map_chr(auditor_online, "# Full Bathrooms")),
    n_half_bathrooms = as.integer(purrr::map_chr(auditor_online, "# Half Bathrooms")),
    online_market_total_value = readr::parse_number(purrr::map_chr(auditor_online, "Market Total Value"))
  ) |>
  dplyr::select(-auditor_online)

codec::dpkg_write(
  d_auditor_online_parcels,
  name = "auditor_online_parcels",
  version = "0.2.0",
  homepage = "https://github.com/geomarker-io/parcel",
  dir = "auditor_online_parcels"
) |>
  codec::dpkg_gh_release()
