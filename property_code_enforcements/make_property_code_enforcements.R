library(dplyr)
library(sf)
library(addr) # pak::pak("cole-brokamp/addr")
library(dpkg) # pak::pak("cole-brokamp/dpkg")

code_enforcement_url <- "https://data.cincinnati-oh.gov/api/views/cncm-znd6/rows.csv?accessType=DOWNLOAD"

raw_data <-
  readr::read_csv(
    code_enforcement_url,
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
  filter(
    !DATA_STATUS_DISPLAY %in% c(
      "Closed - No Violation",
      "Closed - No Violations Found",
      "Duplicate Case",
      "Closed - Duplicate Complaint"
    )
  ) |>
  mutate(description = stringr::str_to_lower(SUB_TYPE_DESC)) |> 
  select(
    id = NUMBER_KEY, 
    date = ENTERED_DATE,
    description,
    status = DATA_STATUS_DISPLAY,
    address = FULL_ADDRESS,
    lat_jittered = LATITUDE,
    lon_jittered = LONGITUDE,
  ) |>
  filter(address != "")

# unique addresses
d_address <- 
  tibble::tibble(address = unique(raw_data$address)) |>
  mutate(addr = addr::addr(glue::glue("{address} Anytown XX 00000")))

# match with addr::cagis_addr reference addresses included in the package
d_address_match <- 
  purrr::map2(
    seq(from = 1, to = nrow(d_address), by = 100), 
    c(seq(from = 100, to = nrow(d_address), by = 100), nrow(d_address)),
    \(x, y) 
    addr_match_street_name_and_number(
      x = d_address$addr[x:y], 
      ref_addr = cagis_addr()$cagis_addr,
      stringdist_match = "osa_lt_1", 
      match_street_type = TRUE, 
      simplify = TRUE
    ), 
  .progress = TRUE
  )

d_address_match_tibble <- purrr::map(d_address_match, \(x) tibble::tibble(cagis_addr = x))
d_address_match_tibble <- bind_rows(d_address_match_tibble)

d_address <- bind_cols(d_address, d_address_match_tibble)

saveRDS(d_address, "matched_addr.rds")

d <- 
  raw_data |> 
  left_join(d_address, by = "address") |>
  left_join(cagis_addr(), by = "cagis_addr") |>
  mutate(cagis_parcel_id = purrr::map_chr(cagis_addr_data, \(x) ifelse(!is.null(x), x$cagis_parcel_id[1], NA))) |>
  select(-cagis_addr_data)

saveRDS(d, "property_code_enforcements.rds")

d_address |>
  group_by(is.na(cagis_addr)) |>
  tally() |>
  mutate(pct = n/sum(n)*100)

d |>
  group_by(is.na(cagis_parcel_id)) |>
  tally() |>
  mutate(pct = n/sum(n)*100)

d_dpkg <-
  d |>
  dpkg::as_dpkg(
    name = "property_code_enforcements",
    version = "1.1.0",
    title = "Property Code Enforcements",
    homepage = "https://github.com/geomarker-io/parcel",
    description = paste(readLines(fs::path("property_code_enforcements", "README", ext = "md")), collapse = "\n")
  )

# dpkg::dpkg_gh_release(d_dpkg, draft = FALSE)