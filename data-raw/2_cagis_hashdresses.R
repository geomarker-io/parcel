library(data.table)

d_ham <-
  cagis_parcels |>
  select(parcel_id, starts_with("property_addr")) |>
  na.omit() |>
  transmute(
    parcel_id,
    address = glue::glue("{property_addr_number} {property_addr_street} {property_addr_suffix}")
  )

d_ham_expand <- address_expand(d_ham, hashdress = TRUE, quiet = FALSE)

cagis_hashdress <-
  d_ham_expand |>
  rowwise(parcel_id, parsed_address) |>
  summarize(hashdress = hashdresses) |>
  as.data.table(key = "hashdress")

usethis::use_data(cagis_hashdresses, overwrite = TRUE)
