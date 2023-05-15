skip_if_no_usaddress <- function() {
  have_usaddress <- reticulate::py_module_available("usaddress")
  if (!have_usaddress) {
    skip("usaddress python module not available for testing")
  }
}

test_that("tag_address works", {
  skip_if_no_usaddress()
  tag_address("3333 Burnet Ave Cincinnati OH 45219", clean = FALSE) |>
    expect_identical(
      tibble::tibble(
        street_number = "3333",
        street_name = "Burnet Ave",
        city = "Cincinnati",
        state = "OH",
        zip_code = "45219"
      )
    )
  tag_address("3333 Burnet Ave Cincinnati OH 45219") |>
    expect_identical(
      tibble::tibble(
        street_number = "3333",
        street_name = "burnet ave",
        city = "cincinnati",
        state = "oh",
        zip_code = "45219"
      )
    )
})

test_that("tag_address returns empty data.frame if repeated label error happens", {
  skip_if_no_usaddress()
  tag_address(address = "3333 Burnet Ave 3333 Burnet Ave Cincinnati OH 45219") |>
    expect_identical(
      tibble::tibble(
        street_number = NA,
        street_name = NA,
        city = NA,
        state = NA,
        zip_code = NA
      )
    )
})

test_that("create_address_stub works on addresses without zipcodes", {
  skip_if_no_usaddress()
  c("222 east central parkway", "352 Helen St", "224 Woolper Ave") |>
    create_address_stub(filter_zip = FALSE) |>
    expect_equal(c("222 east central parkway", "352 helen st", "224 woolper ave"))
  })

test_that("create_address_stub gives helpful error message on addresses without zipcodes and default setting of filter_zip=TRUE", {
  skip_if_no_usaddress()
  c("222 east central parkway", "352 Helen St", "224 Woolper Ave") |>
    create_address_stub() |>
    expect_error(regexp = "there are no zip codes found")
  })

test_that("create_address_stub works", {
  skip_if_no_usaddress()
  c(
    "224 Woolper Ave Cincinnati OH 45220",
    "222 East Central Parkway Cincinnati OH 45220",
    "352 Helen St Cincinnati OH 45202",
    "5377 Bahama Ter Apt 1 Cincinnati Ohio 45223",
    "5377 Bahama Te Apt 1 Cincinnati Ohio 45223",
    "1851 Campbell Dr Hamilton Ohio 45011", # outside hamilton county
    "2 Maplewood Dr Ryland Heights, KY 41015", # outside ohio
    "736 South fredshuttles Apt 3 CINCINNATI Ohio 45229", # parsed as "house", not "house_number" and "road"
    "NA"
  ) |>
    create_address_stub(filter_zip = TRUE) |>
    expect_equal(c(
      "224 woolper ave", "222 east central parkway", "352 helen st",
      "5377 bahama ter", "5377 bahama te", NA, NA,
      "736 south fredshuttles", NA
    ))
})

test_that("clean address text works", {
  expect_identical(
    clean_address(c(
      "3333 Burnet Ave, Cincinnati, OH 45229-1234",
      "PO Box 1234, Cincinnati,         OH 45229",
      "2600    CLIFTON AVE., Cincinnati, OH 45229"
    )),
    c(
      "3333 burnet ave cincinnati oh 45229-1234",
      "po box 1234 cincinnati oh 45229",
      "2600 clifton ave cincinnati oh 45229"
    )
  )
})
