# example using functions in package to match address in "Hospital Admissions.csv" file with parcel reference:
library(dplyr)
library(readr)
# make sure {parcel} is loaded to access read/write paths inside package during development

if (Sys.which("csvlink") == "") {
  message("csvlink command is unavailable")
  message("run reticulate::py_install('csvdedupe', pip = TRUE) to install it")
  message("reticulate::py_install('dedupe-variable-address', pip = TRUE) is also required")
}

td <- tempdir()

CODECtools::read_tdr_csv(fs::path_package("parcel", "cagis_parcels")) |>
  select(parcel_id, parcel_address) |>
  mutate(parcel_address_stub = create_address_stub(parcel_address, filter_zip = FALSE)) |>
  write_csv(fs::path(td, "d_ref.csv"))

d <-
  read_csv("Hospital Admissions.csv",
           na = c("NA", "-", "NULL"),
           col_types = cols_only(PAT_ENC_CSN_ID = col_character(),
                                 PAT_ADDR_1 = col_character(),
                                 PAT_ADDR_2 = col_character(),
                                 PAT_CITY = col_character(),
                                 PAT_STATE = col_character(),
                                 PAT_ZIP = col_character())) |>
  tidyr::unite(
    "patient_address",
    c(PAT_ADDR_1, PAT_ADDR_2, PAT_CITY, PAT_STATE, PAT_ZIP),
    sep = " ", na.rm = TRUE
  ) |>
  mutate(patient_address_stub = create_address_stub(patient_address, filter_zip = TRUE))

d |>
  select(PAT_ENC_CSN_ID, patient_address_stub) |>
  na.omit() |>
  distinct() |>
  write_csv(fs::path(td, "d.csv"))

withr::with_dir(td, {
  system2("csvlink", "d.csv d_ref.csv --field_names_1 patient_address_stub --field_names_2 parcel_address_stub --field-definition Address --inner_join --recall_weight 2 --output_file inner.csv")
})
# recall_weight is how many times more we care about recall (i.e. sens) compared to precision (i.e., PPV)

# TODO fix the temporary choice to return the first match if more than one match is returned
result <-
  readr::read_csv(fs::path(td, "inner.csv"), col_types = "c") |>
  select(patient_address_stub, parcel_id) |>
  distinct() |>
  group_by(patient_address_stub) |>
  summarize(parcel_id = parcel_id[1], .groups = "drop")

d_out <- left_join(d, result, by = c("patient_address_stub"))

readr::write_csv(d_out, "riseup_parcel_matches.csv")

message("matched among hamilton zipcode encounters:")
d_out |>
  filter(!is.na(patient_address_stub)) |>
  group_by(!is.na(parcel_id)) |>
  summarize(n = n()) |>
  mutate(`%` = scales::percent(n / sum(n)))

message("matched among all encounters:")
d_out |>
  group_by(!is.na(parcel_id)) |>
  summarize(n = n()) |>
  mutate(`%` = scales::percent(n / sum(n)))
