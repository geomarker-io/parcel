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

rd$centroid_lon <- st_coordinates(rd_centroids)[, "X"]
rd$centroid_lat <- st_coordinates(rd_centroids)[, "Y"]

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

d_dpkg <-
  d |>
  dpkg::as_dpkg(
    name = "cagis_parcels",
    version = "1.1.0",
    homepage = "https://github.com/geomarker-io/parcel",
    description = paste(readLines(fs::path("cagis_parcels", "README", ext = "md")), collapse = "\n")
  )

dpkg::dpkg_gh_release(d_dpkg, draft = FALSE)
