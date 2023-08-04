library(dplyr, warn.conflicts = FALSE)

d <-
  fs::path_package("parcel", "cagis_parcels") |>
  codec::read_tdr_csv()

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

d$auditor_online <-
  mappp::mappp(d$parcel_id, scrape_hamilton_parcel, parallel = TRUE, cache = TRUE, cache_name = "auditor_online_cache")

# TODO stop early with ~ 30k results and work on data cleaning

d |>
mutate(year_built = purrr::map_int(auditor_online, "Year Built")) |>
  add_col_attrs(year_built, title = "Year Built") |>
  mutate(total_rooms = purrr::map_dbl(auditor_online, "Total Rooms")) |>
  add_col_attrs(total_rooms, title = "Total Rooms") |>

d <-
  d |>
  add_type_attrs() |>
  add_attrs(
    name = "hamilton_online_parcels",
    version = paste0(packageVersion("parcel")),
    title = "Hamilton Online Parcels",
    homepage = "https://github.com/geomarker-io/hamilton_parcels",
    description = "A curated property-level data resource derived from scraping the Hamilton County, OH Auditor Online: https://wedge1.hcauditor.org/. Data was scraped for only residential parcels in CAGIS Parcels; see homepage for details."
  )

write_tdr_csv(d, dir = fs::path_package("parcel"))
