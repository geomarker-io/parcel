usaddress <- NULL
dedupe <- NULL

.onLoad <- function(libname, pkgname) {
  reticulate::configure_environment(pkgname)
  usaddress <<- reticulate::import("usaddress", delay_load = TRUE, convert = TRUE)
  dedupe <<- reticulate::import("dedupe", delay_load = TRUE, convert = FALSE)
  py <<- reticulate::import_builtins(convert = TRUE)
}

utils::globalVariables("address")
utils::globalVariables("input_address")
utils::globalVariables("address_stub")
utils::globalVariables("parcel")
utils::globalVariables("parcel_id")
utils::globalVariables("zip_code")
utils::globalVariables("street_number")
utils::globalVariables("street_name")
utils::globalVariables("gaz")
utils::globalVariables("f")
utils::globalVariables("high_score")
utils::globalVariables("score")
utils::globalVariables("apt_id")
