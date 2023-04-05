library(data.table)
library(dplyr)
library(CODECtools)
# make sure parcel is loaded

d_ham <-
  read_tdr_csv(fs::path_package("parcel", "cagis_parcels")) |>
  select(parcel_id, parcel_address)

d_ham_expand <- d_ham |> mutate(expanded_addresses = expand_addresses(parcel_address))

d_hd <- d_ham_expand |> mutate(hashdress = hashdress(expanded_addresses))

cagis_hashdresses <-
  d_hd |>
  select(-expanded_addresses) |>
  tidyr::unnest(cols = hashdress, keep_empty = TRUE) |>
  as.data.table(key = "hashdress")

saveRDS(cagis_hashdresses, file = fs::path(fs::path_package("parcel"), "cagis_hashdresses.rds"))
