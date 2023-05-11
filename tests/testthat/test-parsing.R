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
      "736 south fredshuttles", NA))
})


## test_that("add_parcel_id works", {
##   skip_on_ci()

##   d <- tibble::tibble(
##     address =  c(
##       "224 Woolper Ave Cincinnati OH 45220",
##       "222 East Central Parkway Cincinnati OH 45220",
##       "352 Helen St Cincinnati OH 45202",
##       "5377 Bahama Ter Apt 1 Cincinnati Ohio 45223",
##       "5377 Bahama Te Apt 1 Cincinnati Ohio 45223",
##       "1851 Campbell Dr Hamilton Ohio 45011", # outside hamilton county
##       "2 Maplewood Dr Ryland Heights, KY 41015", # outside ohio
##       "736 South fredshuttles Apt 3 CINCINNATI Ohio 45229" # parsed as "house", not "house_number" and "road"
##       ),
##     id = letters[1:8])

##   d |>
##     mutate(parcel_ids = add_parcel_id(address))

##   expect_equal(length(expands), 10)
##   expect_equal(sapply(expands, length), c(2, 2, 4, 1, 1, 2, 6, 2, 1, 1))
##   expect_identical(is.na(expands[[10]]), TRUE)
##   expect_identical(expands[[9]], "cincinnati ohio 45229")
##   expands_hd <- hashdress(expands)
##   expect_equal(length(expands_hd), 10)
##   expect_equal(sapply(expands_hd, length), c(2, 2, 4, 1, 1, 2, 6, 2, 1, 1))
##   expect_equal(expands_hd[[1]], c("51631215fa206a2d09c55d8feb505b85", "92c767e558294f4f9a8692c2f22d22d4"))
## })
