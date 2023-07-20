# make sure {parcel} is loaded to access read/write paths inside package during development

parcel_addresses <-
  fs::path_package("parcel", "cagis_parcels") |>
  codec::read_tdr_csv() |>
  dplyr::select(parcel_id, parcel_address) |>
  dplyr::mutate(parcel_address_stub = create_address_stub(parcel_address, filter_zip = FALSE))

data_ref <-
  purrr::map(1:nrow(parcel_addresses), \(.) list(
    address = parcel_addresses$parcel_address_stub[.])) |>
  rlang::set_names(parcel_addresses$parcel_id)

saveRDS(data_ref, fs::path(fs::path_package("parcel"), "parcel_address_stubs.rds"))
