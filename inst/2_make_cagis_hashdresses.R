library(data.table)
library(dplyr)
library(CODECtools)
# make sure parcel is loaded


## # TODO don't use docker for address parsing anymore -- only for address expansion (hashdress)
## # still compare approaches to using docker postal for address hashing and matching, tho

d_ham <-
  read_tdr_csv(fs::path_package("parcel", "cagis_parcels")) |>
  tidyr::unite(col = "address",
               tidyselect::any_of(c("property_addr_number", "property_addr_street", "property_addr_suffix")),
               sep = " ", na.rm = TRUE, remove = FALSE) |>
  select(parcel_id, address)

d_ham_expand <- hashdress(d_ham, address_stub_components = c("parsed.house_number", "parsed.road"))

cagis_hashdresses <-
  d_ham_expand |>
  rename(cagis_address = address) |>
  select(-expanded_addresses) |>
  tidyr::unnest(cols = hashdresses, keep_empty = TRUE) |>
  rename(hashdress = hashdresses) |>
  as.data.table(key = "hashdress")

cagis_hashdresses <-
  cagis_hashdresses |>
  filter(!is.na(address_stub))

usethis::use_data(cagis_hashdresses, overwrite = TRUE)

#' CAGIS hashdresses
#'
#' The parcel identifiers and a property address (consisting of
#' property_addr_number, property_addr_street, property_addr_suffix)
#' for each parcel are `hashdress()`ed using the parsed street number and street name.
#' This object is used to match parcel identifiers
#' to hashdresses computed on other, real-world addresses. Note that
#' the five digit ZIP code is not included in CAGIS data, and wasn't used to
#' compute the hashdress.  These hashdresses are specific to Hamilton
#' County, OH.
## "cagis_hashdresses"
