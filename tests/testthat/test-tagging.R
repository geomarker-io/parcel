skip_if_no_dedupe <- function() {
  have_dedupe <- reticulate::py_module_available("dedupe")
  if (!have_dedupe) {
    skip("dedupe python module not available for testing")
  }
}

## cagis_parcel <-
##   codec::read_tdr_csv(fs::path_package("parcel", "cagis_parcels")) |>
##   dplyr::select(-property_addr_number, -property_addr_street, -property_addr_suffix)

## cagis_parcel$parcel_address_stub <- create_address_stub(cagis_parcel$parcel_address, filter_zip = FALSE)
