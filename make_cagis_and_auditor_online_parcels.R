library(sf)
library(dplyr, warn.conflicts = FALSE)

tmp <- tempfile(fileext = ".zip")
download.file("https://www.cagis.org/Opendata/Auditor/Parcels2024.gdb.zip", tmp)
unzip(tmp, exdir = tempdir())

rd <-
  st_read(dsn = fs::path(tempdir(), "Parcels2024.gdb"), layer = "HAM_PARCELS_MERGED_W_CONDOS") |>
  st_zm()

rd_centroids <-
  rd |>
  select(Shape) |>
  st_cast("MULTIPOLYGON") |>
  st_centroid() |>
  st_transform(st_crs(4326))

rd$centroid_lon <- st_coordinates(rd_centroids)[ , "X"]
rd$centroid_lat <- st_coordinates(rd_centroids)[ , "Y"]

d <- st_drop_geometry(rd) |>
  tibble::as_tibble()

d <- distinct(d, AUDPTYID, .keep_all = TRUE)

d <- d |>
  tidyr::unite(
    col = "parcel_address",
    tidyselect::any_of(c("ADDRNO", "ADDRST", "ADDRSF")),
    sep = " ", na.rm = TRUE, remove = FALSE
  )

# remove those without a parcel_id
d <- filter(d, !is.na(AUDPTYID))
# remove missing property address number or street
d <- filter(d, (!is.na(ADDRNO)) & (!is.na(ADDRST)))

# filter to residential land use codes
lu_keepers <-
  c(
    "single family dwelling" = "510",
    "two family dwelling" = "520",
    "three family dwelling" = "530",
    "condominium unit" = "550",
    "apartment, 4-19 units" = "401",
    "apartment, 20-39 units" = "402",
    "apartment, 40+ units" = "403",
    "mobile home / trailer park" = "415",
    "other commercial housing" = "419",
    "office / apartment over" = "431",
    "boataminium" = "551",
    "landominium" = "555",
    "manufactured home" = "560",
    "other residential structure" = "599",
    "condo or pud garage" = "552",
    "metropolitan housing authority" = "645",
    "lihtc res" = "569"
  )

d <- d |>
  filter(CLASS %in% lu_keepers) |>
  mutate(land_use = forcats::fct_recode(as.factor(CLASS), !!!lu_keepers))

d <- d |>
  transmute(
    parcel_id = AUDPTYID,
    centroid_lat, centroid_lon,
    parcel_address,
    parcel_addr_number = ADDRNO,
    parcel_addr_street = ADDRST,
    parcel_addr_suffix = ADDRSF,
    land_use = land_use,
    condo_id = CONDOMTCH,
    condo_unit = UNIT,
    market_total_value = MKT_TOTAL_VAL,
    acreage = ACREDEED,
    homestead = HMSD_FLAG == "Y",
    rental_registration = RENT_REG_FLAG == "Y"
  )

codec::dpkg_write(d, name = "cagis_parcels", version = "1.1.0",
                  homepage = "https://github.com/geomarker-io/parcel")

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
## httr::set_config(httr::user_agent("Mozilla/5.0 (Windows NT 5.1; rv:52.0) Gecko/20100101 Firefox/52.0"))
## d$auditor_online <-
##   mappp::mappp(d$parcel_id, scrape_hamilton_parcel, parallel = FALSE, cache = TRUE, cache_name = "auditor_online_cache")
## # save dated copy of parcel scrape
## saveRDS(d, "./auditor_online_scrape_2024-01-16.rds")

d_scrape <- readRDS("./auditor_online_scrape_2024-01-16.rds")

d_auditor_online_parcels <-
  d_scrape |>
  select(parcel_id, auditor_online) |>
  mutate(year_built = as.integer(purrr::map_chr(auditor_online, "Year Built"))) |>
  mutate(n_total_rooms = as.integer(purrr::map_chr(auditor_online, "Total Rooms"))) |>
  mutate(n_bedrooms = as.integer(purrr::map_chr(auditor_online, "# Bedrooms"))) |>
  mutate(n_full_bathrooms = as.integer(purrr::map_chr(auditor_online, "# Full Bathrooms"))) |>
  mutate(n_half_bathrooms = as.integer(purrr::map_chr(auditor_online, "# Half Bathrooms"))) |>
  mutate(online_market_total_value = readr::parse_number(purrr::map_chr(auditor_online, "Market Total Value"))) |>
  select(-auditor_online)

codec::dpkg_write(d_auditor_online_parcels, "auditor_online_parcels",
  version = "1.1.0",
  homepage = "https://github.com/geomarker-io/parcel"
)
