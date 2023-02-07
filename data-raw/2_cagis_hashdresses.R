library(data.table)
library(dplyr)
#devtools::load_all()

d_ham <-
  cagis_parcels |>
  select(parcel_id, starts_with("property_addr")) |>
  na.omit() |>
  tidyr::unite(col = "address",
               tidyselect::any_of(c("property_addr_number", "property_addr_street", "property_addr_suffix")),
               sep = " ", na.rm = TRUE, remove = FALSE) |>
  select(parcel_id, address)

d_ham_expand <- hashdress(d_ham)

cagis_hashdresses <-
  d_ham_expand |>
  rename(cagis_address = address) |>
  rowwise(parcel_id, cagis_address) |>
  summarize(hashdress = hashdresses, .groups = "drop") |>
  as.data.table(key = "hashdress")

usethis::use_data(cagis_hashdresses, overwrite = TRUE, compress = "xz")
