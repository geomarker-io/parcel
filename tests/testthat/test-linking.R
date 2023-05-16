skip_if_no_dedupe <- function() {
  have_dedupe <- reticulate::py_module_available("dedupe")
  if (!have_dedupe) {
    skip("dedupe python module not available for testing")
  }
}


test_that("link_parcel works", {
  skip_if_no_dedupe()

  my_addresses <- c(
    "224 Woolper Ave Cincinnati OH 45220",
    "222 East Central Parkway Cincinnati OH 45220",
    "352 Helen St Cincinnati OH 45202",
    "5377 Bahama Ter Apt 1 Cincinnati Ohio 45223",
    "5377 Bahama Te Apt 1 Cincinnati Ohio 45223",
    "1851 Campbell Dr Hamilton Ohio 45011", # outside hamilton county
    "2 Maplewood Dr Ryland Heights, KY 41015", # outside ohio
    "736 South fredshuttles Apt 3 CINCINNATI Ohio 45229"
  )

  my_addr_links <- link_parcel(my_addresses)

  expect_equal(nrow(my_addr_links), 3)

  expect_equal(my_addr_links$parcel_id,
               c("2170054005900", "2270001008600", "2270001008600"))
  })
