library(tidyverse)

d_parcel <- as_tibble(fr::read_fr_tdr(fs::path_package("parcel", "cagis_parcels")))

d_apartment_ids <-
  d_parcel |>
  mutate(complex_id = case_when(
    # villages at roll hill also includes nottingham RD but no parcel record exists
    parcel_addr_street %in% c("PRESIDENT", "WILLIAMSBURG") ~ "villages_at_roll_hill", 
    parcel_addr_street == "BAHAMA" ~ "bahama",
    parcel_addr_street == "HAWAIIAN" ~ "hawaiian",
    parcel_addr_street == "DEWDROP" ~ "dewdrop", 
    parcel_addr_street == "HAWAIIAN" ~ "hawaiian",
    parcel_addr_street == "WINNESTE" & parcel_addr_number %in% 4800:5099 ~ "winton_terrace",
    parcel_addr_street == "GARDEN VIEW" & parcel_addr_number == 5443 ~ "silver_oaks",
    parcel_addr_street == "GARDENHILL" & parcel_addr_number %in% 5500:5799 ~ "silver_oaks",
    parcel_addr_street == "WINTONVIEW" ~ "silver_oaks",
    parcel_addr_street == "WINNESTE" & parcel_addr_number %in% 5300:5499 ~ "winton_hills_mha",
    parcel_addr_street %in% c("STRAND", "HOLLAND", "VIVIAN", "DUTCH COLONY") ~ "winton_hills_mha",
    parcel_addr_street == "CLOVERNOOK" & parcel_addr_number == "7600 7" ~ "clovernook",
    parcel_addr_street == "WALDEN GLEN" ~ "walden_glen",
  )) |>
  filter(!is.na(complex_id))

write_csv(d_apartment_ids, "inst/apt_complex_parcel_ids.csv")

apt_pseudoids <- 
  d_apartment_ids |>
  group_by(complex_id) |>
  summarize(land_use = collapse::fmode(land_use), 
            market_total_value = sum(market_total_value)) |>
  mutate(land_use = case_when(
    str_sub(land_use, 1, 9) == "apartment" ~ "apartment, 40+ units", 
    TRUE ~ land_use))

write_csv(apt_pseudoids, "inst/apt_complex_pseudoids.csv")
