library(dplyr)
library(sf)
library(CODECtools)
# make sure {parcel} is loaded

parcel_gdb <- fs::path_package("parcel", "ham_merge_parcels.gdb")

if (!fs::file_exists(parcel_gdb)) {
  tmp <- tempfile(fileext = ".zip")
  download.file("https://www.cagis.org/Opendata/Auditor/HAM_MERGE_PARCELS.gdb.zip", tmp, timeout = 1000, method = "wget")
  unzip(tmp, exdir = fs::path_package("parcel"))
}

## st_layers(dsn = "data-raw/HAM_MERGE_PARCELS.gdb")
rd <-
  st_read(dsn = parcel_gdb, layer = "HAM_PARCELS_MERGED_W_CONDOS") |>
  st_zm(drop = TRUE, what = "ZM") |>
  st_cast("MULTIPOLYGON")

coords <-
  rd |>
  st_centroid() |>
  st_transform(4326) |>
  st_coordinates()

rd <-
  rd |>
  mutate(parcel_centroid_lon = coords[, "X"],
         parcel_centroid_lat = coords[, "Y"]) |>
  st_drop_geometry(d) |>
  tibble::as_tibble()

d <-
  tibble::tibble(parcel_id = rd$AUDPTYID) |>
  add_col_attrs(parcel_id,
    title = "Parcel Identifier",
    description = "uniquely identifies properties; the auditor Parcel Number"
  ) |>
  mutate(property_addr_number = rd$ADDRNO) |>
  add_col_attrs(property_addr_number,
    title = "Address Number"
  ) |>
  mutate(property_addr_street = rd$ADDRST) |>
  add_col_attrs(property_addr_street,
    title = "Address Street"
  ) |>
  mutate(property_addr_suffix = rd$ADDRSF) |>
  add_col_attrs(property_addr_suffix,
    title = "Address Suffix"
  ) |>
  mutate(parcel_centroid_lat = rd$parcel_centroid_lat) |>
  add_col_attrs(parcel_centroid_lat,
                title = "Parcel Centroid Latitude",
                description = "coordinates derived from centroid of parcel shape") |>
  mutate(parcel_centroid_lon = rd$parcel_centroid_lon) |>
  add_col_attrs(parcel_centroid_lon,
                title = "Parcel Centroid Longitude",
                description = "coordinates derived from centroid of parcel shape") |>
  mutate(market_total_value = rd$MKT_TOTAL_VAL) |>
  add_col_attrs(market_total_value,
    title = "Market Total Value"
  ) |>
  mutate(land_use = rd$CLASS) |>
  add_col_attrs(land_use,
    title = "Auditor Land Use"
  ) |>
  mutate(acreage = rd$ACREDEED) |>
  add_col_attrs(acreage,
    title = "Acreage"
  ) |>
  mutate(homestead = rd$HMSD_FLAG == "Y") |>
  add_col_attrs(homestead,
    title = "Homestead"
  ) |>
  mutate(RED_25_FLAG = rd$RED_25_FLAG == "Y") |>
  mutate(annual_taxes = rd$ANNUAL_TAXES) |>
  add_col_attrs(annual_taxes,
    title = "Annual Taxes"
  ) |>
  mutate(unpaid_taxes = rd$DELQ_TAXES - rd$DELQ_TAXES_PD) |>
  add_col_attrs(unpaid_taxes,
    title = "Unpaid Taxes",
    description = "Calculated as `delinquent taxes` minus `delinquent taxes paid`"
  )

nrow(d) # n = 354,521
# remove those without a parcel_id
d <- filter(d, !is.na(parcel_id))
nrow(d) # 352,812
# remove missing property address number or street
d <- filter(d, (!is.na(property_addr_number)) & (!is.na(property_addr_street)))
nrow(d) # 321,113
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
nrow(d) # 286,059

## levels(d$land_use)
d <-
  d |>
  add_type_attrs() |>
  add_attrs(
    name = "cagis_parcels",
    version = paste0(packageVersion("parcel")),
    title = "CAGIS Parcels",
    homepage = "https://github.com/geomarker-io/hamilton_parcels",
    description = "A curated property-level data resource derived from the Hamilton County, OH Auditor data distributed through CAGIS Open Data: https://cagismaps.hamilton-co.org/cagisportal/mapdata/download"
  )

write_tdr_csv(d, dir = fs::path_package("parcel"))
