library(dplyr)
library(sf)

if (!file.exists("data-raw/HAM_MERGE_PARCELS.gdb")) {
  tmp <- tempfile(fileext = ".zip")
  download.file("https://www.cagis.org/Opendata/Auditor/HAM_MERGE_PARCELS.gdb.zip", tmp, timeout = 1000, method = "wget")
  unzip(tmp, exdir = "data-raw")
}

## st_layers(dsn = "data-raw/HAM_MERGE_PARCELS.gdb")

rd <-
  st_read(dsn = "data-raw/HAM_MERGE_PARCELS.gdb", layer = "HAM_PARCELS_MERGED_W_CONDOS") |>
  st_zm(drop = TRUE, what = "ZM") |>
  st_cast("MULTIPOLYGON")

d <-
  rd |>
  select(-everything()) |>
  mutate(parcel_id = rd$AUDPTYID,
         property_addr_number = rd$ADDRNO,
         property_addr_street = rd$ADDRST,
         property_addr_suffix = rd$ADDRSF,
         market_total_value = rd$MKT_TOTAL_VAL,
         land_use = rd$CLASS,
         acreage = rd$ACREDEED,
         homestead = rd$HMSD_FLAG == "Y",
         RED_25_FLAG = rd$RED_25_FLAG == "Y",
         annual_taxes = rd$ANNUAL_TAXES,
         unpaid_taxes = rd$DELQ_TAXES - rd$DELQ_TAXES_PD)

nrow(d) # n = 353,747
# remove those without a parcel_id
d <- filter(d, !is.na(parcel_id))
# missing property address number usually means public property, like a roadway
d <- filter(d, !is.na(property_addr_number))
# filter out rows of duplicated data
d <- filter(d, !duplicated(d))
nrow(d) # n = 320,911

# filter to residential land use codes
lu_keepers <-
  c(
    "residential vacant land" = "500",
    "single family dwelling" = "510",
    "two family dwelling" = "520",
    "three family dwelling" = "530",
    "condominium unit" = "550",
    "apartment, 4-19 units" = "401",
    "apartment, 20-39 units" = "402",
    "apartment, 40+ units" = "403",
    "nursing home / private hospital" = "412",
    "independent living (seniors)" = "413",
    "mobile home / trailer park" = "415",
    "other commercial housing" = "419",
    "office / apartment over" = "431",
    "resid unplat 10-19 acres" = "502",
    "resid unplat 20-29 acres" = "503",
    "resid unplat 30-39 acres" = "504",
    "single fam dw 0-9 acr" = "511",
    "boataminium" = "551",
    "landominium" = "555",
    "manufactured home" = "560",
    "metropolitan housing authority" = "645",
    "condominium office building" = "450",
    "lihtc res" = "569",
    "other residential structure" = "599",
    "condo or pud garage" = "552",
    "charities, hospitals, retir" = "680"
  )

d <- d |>
  filter(land_use %in% lu_keepers) |>
  mutate(land_use = forcats::fct_recode(as.factor(land_use), !!!lu_keepers))
nrow(d) # 286,236

# add lat/lon centroid coordinates
coords <-
  d |>
  st_centroid() |>
  st_transform(4326) |>
  st_coordinates()
d$parcel_centroid_lon <- coords[, "X"]
d$parcel_centroid_lat <- coords[, "Y"]

cagis_parcels <-
  st_drop_geometry(d) |>
  tibble::as_tibble()

usethis::use_data(cagis_parcels, overwrite = TRUE)
