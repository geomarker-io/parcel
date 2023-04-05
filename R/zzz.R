usaddress <- NULL

.onLoad <- function(libname, pkgname) {
  usaddress <<- reticulate::import("usaddress", delay_load = TRUE)
}

utils::globalVariables(".id")
utils::globalVariables("address")
utils::globalVariables("address_stub")
utils::globalVariables("expanded_addresses")
utils::globalVariables("hashdresses")
utils::globalVariables("parcel")
utils::globalVariables("expansions")
utils::globalVariables("zip_code")
utils::globalVariables("street_number")
utils::globalVariables("street_name")
