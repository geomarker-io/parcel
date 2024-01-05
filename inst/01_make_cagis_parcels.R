library(dplyr)
library(sf)
library(fr)

# make sure {parcel} is loaded using devtools::load_all() to access read/write paths inside package during development
if (!fs::file_exists(fs::path_package("parcel", "Parcels2024.gdb"))) {
  tmp <- tempfile(fileext = ".zip")
  download.file("https://www.cagis.org/Opendata/Auditor/Parcels2024.gdb.zip", tmp, timeout = 1000, method = "wget")
  unzip(tmp, exdir = fs::path_package("parcel"))
}

## st_layers(dsn = parcel_gdb)
rd <- st_read(dsn = fs::path_package("parcel", "Parcels2024.gdb"), layer = "HAM_PARCELS_MERGED_W_CONDOS") |>
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

# remove duplicated entries for a parcel id
nrow(d) # 354,763
d <- distinct(d, AUDPTYID, .keep_all = TRUE)
nrow(d) # 353,288

d <- d |>
  tidyr::unite(
    col = "parcel_address",
    tidyselect::any_of(c("ADDRNO", "ADDRST", "ADDRSF")),
    sep = " ", na.rm = TRUE, remove = FALSE
  )

# remove those without a parcel_id
d <- filter(d, !is.na(AUDPTYID))
nrow(d) # 353287
# remove missing property address number or street
d <- filter(d, (!is.na(ADDRNO)) & (!is.na(ADDRST)))
nrow(d) # 321250

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
nrow(d) # 259653

out <-
  d |>
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
  ) |>
  as_fr_tdr(
    name = "cagis_parcels",
    version = paste0(packageVersion("parcel")),
    title = "CAGIS Parcels",
    homepage = "https://github.com/geomarker-io/hamilton_parcels",
    description = "A curated property-level data resource derived from the Hamilton County, OH Auditor data distributed through CAGIS Open Data: https://cagismaps.hamilton-co.org/cagisportal/mapdata/download"
  )

out <- out |>
  update_field("parcel_id",
    description = "uniquely identifies properties; the auditor Parcel Number"
  ) |>
  update_field("condo_id",
    description = "used to match two parcels to the same building of condos"
  ) |>
  update_field("parcel_address",
    description = "derived by pasting parcel_address_{number, street, suffix}` together"
    ) |>
  update_field("centroid_lat",
               description = "calculated as centroid of casted multipolygon geometry and projected from Ohio South to WGS84") |>
  update_field("centroid_lon",
               description = "calculated as centroid of casted multipolygon geometry and projected from Ohio South to WGS84")

write_fr_tdr(out, dir = fs::path_package("parcel"))
