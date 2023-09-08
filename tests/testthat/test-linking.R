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
    "5377 Bahama Ter Apt 1 Cincinnati Ohio 45223",
    "5377 Bahama Te Apt 1 Cincinnati Ohio 45223"
  )
  my_addr_links <- link_parcel(my_addresses, threshold = 0.2)
  expect_equal(nrow(my_addr_links), 3)
  expect_equal(my_addr_links$parcel_id,
               c("2170054005900", "2270001008600", "2270001008600"))
})

test_that("link_parcel works with inst addresses", {
  skip_if_no_dedupe()
  my_addresses <- c(
    "222 E Central Parkway Cincinnati Ohio 45220",
    "222 Central Pkwy Cincinnati Ohio 45220",
    "3333 Burnet Ave Cincinnati Ohio 45219",
    "3031 Eden Ave Cincinnati Ohio 45219",
    "3010 Eden Ave Cincinnati Ohio 45219",
    "341 Erkenbrecher Ave Cincinnati Ohio 45219",
    "350 Erkenbrecher Ave Cincinnati Ohio 45219"
  )
  my_addr_links <- link_parcel(my_addresses, threshold = 0.2)

  expect_equal(length(my_addresses), nrow(my_addr_links) + 1)
  # TODO finish testing; should we remove burnet ave from parcel dataset?

})

test_that("link_parcel threshold works", {
  skip_if_no_dedupe()
  expect_equal(nrow(link_parcel("224 Woolper Ave Cincinnati OH 45220")), 1)
  expect_equal(nrow(link_parcel("224 Woolper Ave Cincinnati OH 45220", threshold = 0.1)), 2)
})

test_that("get_parcel_data works", {
  skip_if_no_dedupe()
  out <-
    c("352 Helen St Cincinnati OH 45202",
    "5377 Bahama Ter Cincinnati Ohio 45223",
    "1851 Campbell Dr Hamilton Ohio 45011") |>
    get_parcel_data()
  expect_equal(nrow(out), 3)
  expect_equal(as.vector(out$homestead), c(NA, FALSE, NA))
  expect_equal(as.vector(out$parcel_id), c(NA, "2270001008600", NA))
  expect_equal(as.vector(out$year_built), c(NA, 1968, NA))
  expect_equal(as.vector(out$n_total_rooms), c(NA, 8, NA))
  expect_equal(as.vector(out$online_market_total_value), c(NA, 164610, NA))
  })

test_that("get_parcel_data only returns 1 row, possibly TIED_MATCH, per input address", {
  skip_if_no_dedupe()
  c("5377 Bahama Ter Cincinnati Ohio 45223", "419 Elm St. Cincinnati OH 45238", "323 Fifth St W Cincinnati OH 45202") |>
    get_parcel_data() |>
    nrow() |>
    expect_equal(3)
})
