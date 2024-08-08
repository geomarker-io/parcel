library(dplyr)
library(sf)
library(addr) # pak::pak("cole-brokamp/addr")

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
  mutate(SUB_TYPE_DESC = stringr::str_to_lower(SUB_TYPE_DESC),
         address = stringr::str_to_lower(FULL_ADDRESS), 
        address = clean_address_text(address)) |> 
  filter(address != "")

# pull unique addresses to reduce computation time
d_address <- tibble::tibble(address = unique(raw_data$address))

# convert address character strings into an addr vector
d_address$addr <- as_addr(d_address$address)

# batch process for memory reasons (because using addr_match_line_one instead of looping over ZIPs)
d_address <- 
  d_address |> 
  mutate(group = rep(1:(nrow(d_address)/880), times = 880))

d_address_list <- group_split(group_by(d_address, group))

# match with addr::cagis_addr reference addresses included in the package
d_address_list <- 
  purrr::map(
    d_address_list, 
    \(x) 
    x |>
    mutate(cagis_addr_matches = addr:::addr_match_line_one(addr, cagis_addr$cagis_addr)), 
  .progress = TRUE
  )

# collapse back to one tibble
d <- bind_rows(d_address_list)

d <- 
  d |>
  mutate(
    addr_match_result =
      case_when(
        purrr::map_lgl(cagis_addr_matches, is.null) ~ NA,
        purrr::map_dbl(cagis_addr_matches, vctrs::vec_size) == 0 ~ "no_match",
        purrr::map_dbl(cagis_addr_matches, vctrs::vec_size) == 1 ~ "single_match",
        purrr::map_dbl(cagis_addr_matches, vctrs::vec_size) > 1 ~ "multi_match",
        .default = "foofy"
      ) |>
      factor(levels = c("no_match", "single_match", "multi_match"))
  )

summary(d$addr_match_result) # include in readme (only keep single match)

# d <- readRDS("property_code_enforcements_matched_addr.rds")

raw_data <- 
  raw_data |> 
  left_join(d, by = "address") |> 
  select(-group)

summary(raw_data$addr_match_result) # include in readme (only keep single match)

# tummarize enforcements by (CAGIS) address/parcel id
d_enforcements <- 
  raw_data |>
  filter(addr_match_result == "single_match") |>
  tidyr::unnest(cols = cagis_addr_matches) |>
  rename(cagis_addr = cagis_addr_matches) |>
  left_join(cagis_addr, by = "cagis_addr") |> # rep rows for condos.. is this parcel id valid? 
  tidyr::unnest(cols = cagis_addr_data) |>
  select(
    date = ENTERED_DATE,
    infraction_description = SUB_TYPE_DESC,
    status = DATA_STATUS_DISPLAY, 
    address,
    cagis_addr,
    cagis_parcel_id
  ) 

d_enforcements_unmatched <- 
  raw_data |>
  filter(addr_match_result != "single_match") |>
    select(
      date = ENTERED_DATE,
      infraction_description = SUB_TYPE_DESC,
      status = DATA_STATUS_DISPLAY, 
      address
    )

d_enforcements <- 
  bind_rows(d_enforcements, d_enforcements_unmatched) |>
  arrange(date)

library(dpkg) # pak::pak("cole-brokamp/dpkg@v0.1.0")

d_dpkg <-
  d_enforcements |>
  dpkg::as_dpkg(
    name = "property_code_enforcements",
    version = "1.0.0",
    title = "Property Code Enforcements",
    homepage = "https://github.com/geomarker-io/parcel",
    description = paste(readLines(fs::path("property_code_enforcements", "README", ext = "md")), collapse = "\n")
  )

# dpkg::dpkg_gh_release(d_dpkg, draft = FALSE)