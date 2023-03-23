test_that("hashdress works", {
  skip_on_ci()
  d <-
    tibble::tibble(
      address = c(
        "224 Woolper Ave Cincinnati OH 45220",
        "222 East Central Parkway Cincinnati OH 45220",
        "352 Helen St Cincinnati OH 45202",
        "5377 Bahama Ter Apt 1 Cincinnati Ohio 45223",
        "5377 Bahama Te Apt 1 Cincinnati Ohio 45223",
        "1851 Campbell Dr Hamilton Ohio 45011", # outside hamilton county
        "2 Maplewood Dr Ryland Heights, KY 41015", # outside ohio
        "222 East Central Parkway Cincinnati OH 45220", # non-residential
        "736 South fredshuttles Apt 3 CINCINNATI Ohio 45229", # parsed as "house", not "house_number" and "road"
        "NA"
      ),
      id = letters[1:10]
    )

  d_hd <- hashdress(d, quiet = TRUE)

  expect_equal(names(d_hd), c("address", "id", "address_stub", "expanded_addresses", "hashdresses"))
  expect_equal(nrow(d_hd), 10)

  d_hd_long <- tidyr::unnest(d_hd, cols = hashdresses, keep_empty = TRUE)

  expect_equal(nrow(d_hd_long), 14)

  expect_equal(d_hd_long[["hashdresses"]][1], "c8368081d566abf9dc869c5dc99dc802")

  expect_equal(sum(is.na(d_hd_long$hashdresses)), 2)

  expect_equal(sum(is.na(d_hd_long$hashdresses)), 2)

  expect_equal(sum(is.na(d_hd_long$address)), 0)

})

