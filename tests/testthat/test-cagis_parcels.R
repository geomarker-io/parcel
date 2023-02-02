test_that("cagis_parcels is available", {
  expect_true(is.data.frame(cagis_parcels))
  expect_true(nrow(cagis_parcels) > 0)
  expect_true("parcel_id" %in% names(cagis_parcels))
  expect_true("parcel_centroid_lon" %in% names(cagis_parcels))
  expect_true("parcel_centroid_lat" %in% names(cagis_parcels))
})
