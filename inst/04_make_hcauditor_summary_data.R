library(dplyr, warn.conflicts = FALSE)
library(fr)
# make sure {parcel} is loaded using devtools::load_all() to access read/write paths inside package during development

d <-
  fs::path_package("parcel", "cagis_parcels") |>
  fr::read_fr_tdr() |>
  tibble::as_tibble()

httr::set_config(httr::user_agent("Mozilla/5.0 (Windows NT 5.1; rv:52.0) Gecko/20100101 Firefox/52.0"))

#' scrape hamilton county auditor online summary data
#' This function downloads data from the auditor website, please be polite!
#' @param parcel_id numeric or character parcel identifier
#' @return named character vector
#' @examples
#' scrape_hamilton_parcel("2170054005900")
#' scrape_hamilton_parcel("5000341051800")
scrape_hamilton_parcel <- function(parcel_id){
  haul <-
    glue::glue("https://wedge3.hcauditor.org/view/re/{parcel_id}/2022/summary") |>
    xml2::read_html() |>
    rvest::html_nodes("#property_overview_wrapper td") |>
    rvest::html_text()
  setNames(haul[seq(from = 2, to = length(haul), by = 2)],
           haul[seq(from = 1, to = length(haul), by = 2)])
}

## # to run the very long process of scraping without using a prestored result, run:
## d$auditor_online <-
##   mappp::mappp(d$parcel_id, scrape_hamilton_parcel, parallel = FALSE, cache = TRUE, cache_name = "auditor_online_cache")
## # save dated copy of parcel scrape
## saveRDS(d, "./auditor_online_scrape_2024-01-16.rds")

d <- readRDS("./auditor_online_scrape_2024-01-16.rds")

d_out <-
  d |>
  select(parcel_id, auditor_online) |>
  mutate(year_built = as.integer(purrr::map_chr(auditor_online, "Year Built"))) |>
  mutate(n_total_rooms = as.integer(purrr::map_chr(auditor_online, "Total Rooms"))) |>
  mutate(n_bedrooms = as.integer(purrr::map_chr(auditor_online, "# Bedrooms"))) |>
  mutate(n_full_bathrooms = as.integer(purrr::map_chr(auditor_online, "# Full Bathrooms"))) |>
  mutate(n_half_bathrooms = as.integer(purrr::map_chr(auditor_online, "# Half Bathrooms"))) |>
  mutate(online_market_total_value = readr::parse_number(purrr::map_chr(auditor_online, "Market Total Value"))) |>
  select(-auditor_online)

d_out <- d_out |>
  as_fr_tdr(
    name = "hamilton_online_parcels",
    version = paste0(packageVersion("parcel")),
    title = "Hamilton Online Parcels",
    homepage = "https://github.com/geomarker-io/parcel",
    description = "A curated property-level data resource derived from scraping the Hamilton County, OH Auditor Online: https://wedge1.hcauditor.org/. Data was scraped for only residential parcels in CAGIS Parcels; see homepage for details.") |>
  update_field("online_market_total_value",
               description = "May differ from the market_total_value from CAGIS auditor online data. This value is scraped from the auditor's website.")

write_fr_tdr(d_out, dir = fs::path_package("parcel"))
