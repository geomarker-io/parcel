library(reticulate)
py <- import_builtins()

x <-
  readr::read_csv("Hospital Admissions.csv",
    na = c("NA", "-", "NULL"),
    col_types = readr::cols_only(
      PAT_ENC_CSN_ID = readr::col_character(),
      PAT_ADDR_1 = readr::col_character(),
      PAT_ADDR_2 = readr::col_character(),
      PAT_CITY = readr::col_character(),
      PAT_STATE = readr::col_character(),
      PAT_ZIP = readr::col_character()
    )
  ) |>
  tidyr::unite(
    "patient_address",
    c(PAT_ADDR_1, PAT_ADDR_2, PAT_CITY, PAT_STATE, PAT_ZIP),
    sep = " ", na.rm = TRUE
  ) |>
  dplyr::pull(patient_address) |>
  unique()

input_data <-
  tibble::tibble(
    input_address = x,
    input_address_stub = create_address_stub(x, filter_zip = TRUE)
  ) |>
  dplyr::filter(!is.na(input_address_stub))

set.seed(1)
input_data <- dplyr::slice_sample(input_data, n = 10000)

data_in <-
  purrr::map(1:nrow(input_data), \(.) list(
    address = input_data$input_address_stub[.])) |>
  rlang::set_names(input_data$input_address)
  

var_def <- list(list(field = "address", type = "Address"))

gaz <-
  dedupe$Gazetteer(
    variable_definition = var_def,
    num_cores = 4,
    in_memory = TRUE)

gaz$prepare_training(data_1 = data_in,
                     data_2 = readRDS(fs::path_package("parcel", "parcel_address_stubs.rds")),
                     sample_size = 1500,
                     blocked_proportion = 0.9)


dedupe$console_label(gaz)

gaz$train()



# save training and settings files
training_fl <- fs::path(fs::path_package("parcel"), "training.json")
settings_fl <- fs::path(fs::path_package("parcel"), "learned_settings")
with(py$open(training_fl, "w") %as% f, {
  gaz$write_training(f)
})
with(py$open(settings_fl, "wb") %as% f, {
  gaz$write_settings(f)
})




matches <- gaz$search(data = data_in[1:1000], n_matches = 1, generator = FALSE)

matches$send
