library(dplyr)
library(sf)
library(codec)
library(addr)

code_enforcement_url <- "https://data.cincinnati-oh.gov/api/views/cncm-znd6/rows.csv?accessType=DOWNLOAD"

raw_data <-
  readr::read_csv(code_enforcement_url,
                  col_types = readr::cols_only(
                    SUB_TYPE_DESC = "character",
                    NUMBER_KEY = "character",
                    ENTERED_DATE = readr::col_datetime(format = "%m/%d/%Y %I:%M:%S %p"),
                    FULL_ADDRESS = "character",
                    LATITUDE = "numeric",
                    LONGITUDE = "numeric",
                    DATA_STATUS_DISPLAY = "character"
                  )
  ) |>
  filter(!DATA_STATUS_DISPLAY %in% c(
    "Closed - No Violation",
    "Closed - No Violations Found",
    "Duplicate Case",
    "Closed - Duplicate Complaint"
  )) |>
  mutate(SUB_TYPE_DESC = stringr::str_to_lower(SUB_TYPE_DESC))

# TODO use addr to match to parcel id
# then summarize enforcements by (CAGIS) address/parcel id

d <-
  raw_data |>
  st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326) |>
  st_transform(st_crs(cincy::tract_tigris_2010)) |>
  st_join(cincy::tract_tigris_2010) |>
  mutate(address = stringr::str_to_lower(FULL_ADDRESS))

d_tract <-
  d |>
  st_drop_geometry() |>
  filter(! is.na(census_tract_id_2010)) |>
  nest_by(census_tract_id_2010) |>
  mutate(
    n_violations = nrow(data),
    date_min = as.Date(min(data$ENTERED_DATE)),
    date_max = as.Date(max(data$ENTERED_DATE)),
    n_days = date_max - date_min
  ) |>
  full_join(cincy::tract_tigris_2010, by = "census_tract_id_2010") |>
  select(-data) |>
  st_as_sf()

# change NA to 0 for number of enforcements in tracts without any enforcements
d_tract <- tidyr::replace_na(d_tract, list(n_violations = 0))

# calculate as number of violations per household
hh_per_tract <-
  tigris::blocks(39, 061, year = 2020) |>
  select(census_block_id_2020 = GEOID20, HOUSING20) |>
  cincy::interpolate(to = cincy::tract_tigris_2010, weights = "pop") |>
  st_drop_geometry() |>
  mutate(n_households = round(HOUSING20)) |>
  select(-HOUSING20)

d_tract <-
  d_tract |>
  left_join(hh_per_tract, by = "census_tract_id_2010") |>
  mutate(violations_per_household = n_violations / n_households)

# TODO change to fr 

d_tract <-
  d_tract |>
  st_drop_geometry() |>
  select(census_tract_id_2010, violations_per_household) |>
  ungroup() |>
  add_col_attrs(census_tract_id_2010, description = "census tract identifier") |>
  add_col_attrs(violations_per_household,
                description = "number of property code enforcements per household") |>
  add_attrs(name = "hamilton_property_code_enforcement",
            title = "Hamilton County Property Code Enforcement",
            version = "0.1.3",
            description = "Number of property code enforcements per household by census tract",
            homepage = "https://geomarker.io/hamilton_property_code_enforcement") |>
  add_type_attrs()

write_tdr_csv(d_tract)
# TODO release tract-level to CODEC

# write metadata.md
cat("#### Metadata\n\n", file = "metadata.md", append = FALSE)
codec::glimpse_attr(d_tract) |>
  knitr::kable() |>
  cat(file = "metadata.md", sep = "\n", append = TRUE)
cat("\n#### Schema\n\n", file = "metadata.md", append = TRUE)
d_tract |>
  codec::glimpse_schema() |>
  knitr::kable() |>
  cat(file = "metadata.md", sep = "\n", append = TRUE)