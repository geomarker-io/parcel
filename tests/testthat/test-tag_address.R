skip_if_no_usaddress <- function() {
  have_usaddress <- reticulate::py_module_available("usaddress")
  if (!have_usaddress) {
    skip("usaddress python module not available for testing")
  }
}

test_that("tag_address works", {
  skip_if_no_usaddress()
  tag_address("3333 Burnet Ave Cincinnati OH 45219") |>
    expect_identical(
      tibble::tibble(
        street_number = "3333",
        street_name = "Burnet Ave",
        city = "Cincinnati",
        state = "OH",
        zip_code = "45219"
      )
    )
})
