# make sure {parcel} is loaded to access read/write paths inside package during development

library(reticulate)
py <- import_builtins()

patient_address <-
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
  )

input_data <-
  patient_address |>
  dplyr::mutate(input_address_stub = create_address_stub(patient_address, filter_zip = TRUE)) |>
  dplyr::filter(!is.na(input_address_stub))

# select 10,000 random Hamilton County addresses for model training
set.seed(1)
input_data <- dplyr::slice_sample(input_data, n = 10000)

data_in <-
  purrr::map(1:nrow(input_data), \(.) list(
    address = input_data$input_address_stub[.])) |>
  rlang::set_names(input_data$patient_address)
  
gaz <-
  dedupe$RecordLink(
    variable_definition = list(list(field = "address", type = "Address")),
    num_cores = 1,
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

##### how it would be called in a function to match new input addresses:
with(py$open(fs::path(fs::path_package("parcel"), "learned_settings"), "rb") %as% f, {
  gaz <<- dedupe$StaticRecordLink(f)
})

links <-
  gaz$join(data_1 = data_in,
           data_2 = readRDS(fs::path_package("parcel", "parcel_address_stubs.rds")),
           threshold = 0.5,
           constraint = "many-to-many")
