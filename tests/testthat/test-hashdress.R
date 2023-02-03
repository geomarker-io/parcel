test_that("hashdress works", {

  d <-
    tibble::tibble(
      address = c(
        "224 Woolper Ave Cincinnati OH 45220",
        "222 East Central Parkway Cincinnati OH 45220",
        "352 Helen St Cincinnati OH 45202",
        "5377 Bahama Ter Apt 1 Cincinnati Ohio 45223",
        "5377 Bahama Te Apt 1 Cincinnati Ohio 45223",
        "1851 Campbell Dr Hamilton Ohio 45011",
        "2 Maplewood Dr Ryland Heights, KY 41015"
      ),
      id = letters[1:7]
    )

  d_hd <- hashdress(d, quiet = TRUE)

  expect_equal(names(d_hd), c("address", "id", "address_stub", "expanded_addresses", "hashdresses"))
  expect_equal(nrow(d_hd), 7)

  d_hd_long <-
    d_hd |>
    dplyr::rowwise(address) |>
    dplyr::summarize(expanded_address = expanded_addresses, hashdress = hashdresses, .groups = "drop")

  expect_equal(nrow(d_hd_long), 11)

  expect_equal(d_hd_long[["hashdress"]][1], "c8368081d566abf9dc869c5dc99dc802")

  expect_equal(
    d_hd_long$expanded_address,
    c(
      "224 woolper avenue 45220",
      "222 east central parkway 45220",
      "352 helen saint 45202",
      "352 helen street 45202",
      "5377 bahama terrace 45223",
      "5377 bahama ter 45223",
      "5377 bahama te 45223",
      "1851 campbell doctor 45011",
      "1851 campbell drive 45011",
      "2 maplewood doctor 41015",
      "2 maplewood drive 41015"
    )
  )

  expect_equal(sum(is.na(d_hd_long)), 0)
})

test_that("address_expand works with addresses missing ZIP codes (doesn't print 'NA')", {
  tibble::tibble(address = c("222 East Central Parkway", "222 East Central Parkway 45202")) |>
    hashdress() |>
    dplyr::pull(address_stub) |>
    expect_equal(c("222 east central parkway", "222 east central parkway 45202"))
})

test_that("add_parcel_id works", {

  d <-
    tibble::tibble(
      address = c(
        "224 Woolper Ave Cincinnati OH 45220",
        "224 Woolper Av Cincinnati OH 45220",
        "306 Helen St Cincinnati OH 45202",
        "5377 Bahama Ter Apt 1 Cincinnati Ohio 45223",
        "5377 Bahama Te Apt 1 Cincinnati Ohio 45223", # TODO why?????????
        "1851 Campbell Dr Hamilton Ohio 45011", # outside hamilton county
        "2 Maplewood Dr Ryland Heights, KY 41015", # outside ohio
        "222 East Central Parkway Cincinnati OH 45220" # non-residential
      ),
      id = letters[1:8]
    ) |>
    add_parcel_id() |>
    tidyr::unnest(cols = c(parcel_id))

  expect_equal(is.na(d$parcel_id), c(rep(FALSE, 5), rep(TRUE, 3)))

  expect_equal(d$parcel_id[1:2], rep("2170054005900", 2))

  # TODO parse input addresses so that ZIP codes are not used??

  

})
