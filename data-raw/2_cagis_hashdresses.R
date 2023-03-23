library(data.table)
library(dplyr)
#devtools::load_all()

d_ham <-
  cagis_parcels |>
  select(parcel_id, tidyselect::any_of(c("property_addr_number", "property_addr_street", "property_addr_suffix"))) |>
  na.omit() |>
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
