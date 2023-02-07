test_that("cagis_parcels is available", {
  expect_true(is.data.frame(cagis_parcels))
  expect_true(nrow(cagis_parcels) > 0)
  expect_true("parcel_id" %in% names(cagis_parcels))
  expect_true("parcel_centroid_lon" %in% names(cagis_parcels))
  expect_true("parcel_centroid_lat" %in% names(cagis_parcels))
})

test_that("add_parcel_id works", {
  skip_on_ci()

  d <-
    tibble::tibble(
      address = c(
        "224 Woolper Ave Cincinnati OH 45220",
        "224 Woolper Av Cincinnati OH 45220",
        "306 Helen St Cincinnati OH 45202",
        "5377 Bahama Te Apt 1 Cincinnati Ohio 45223",
        "1851 Campbell Dr Hamilton Ohio 45011", # outside hamilton county
        "2 Maplewood Dr Ryland Heights, KY 41015", # outside ohio
        "222 East Central Parkway Cincinnati OH 45220" # non-residential
      ),
      id = letters[1:7]
    ) |>
    add_parcel_id() |>
    tidyr::unnest(cols = c(parcel_id))

  expect_equal(is.na(d$parcel_id), c(rep(FALSE, 4), rep(TRUE, 3)))

  expect_equal(d$parcel_id[1:2], rep("2170054005900", 2))
})

test_that("hashdress works on addresses missing ZIP codes", {
  tibble::tibble(address = c("222 East Central Parkway", "222 East Central Parkway 45202")) |>
    hashdress() |>
    dplyr::pull(address_stub) |>
    expect_equal(c("222 east central parkway", "222 east central parkway 45202"))
})
