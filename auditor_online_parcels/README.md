
## Hamilton County Auditor Online Data

<!-- badges: start -->
[![latest github release for auditor_online_parcels dpkg](https://img.shields.io/github/v/release/geomarker-io/parcel?sort=date&filter=auditor_online_parcels-*&display_name=tag&label=%5B%E2%98%B0%5D&labelColor=%238CB4C3&color=%23396175)](https://github.com/geomarker-io/parcel/releases?q=auditor_online_parcels&expanded=false)
 <!-- badges: end -->

The `hamilton_online_parcels` tabular data resource contains parcel characteristics scraped from [Hamilton County Auditor Online](https://wedge1.hcauditor.org/) and linked to the parcel identifers in the `cagis_parcels` data package.
Characteristics include the "parcel id", "year built", "number of total rooms", "number of bedrooms", "number of full bathrooms", "number of half bathrooms", and a "market total value" (named `online_total_market_value` to distinguish it from the market total value in `cagis_parcels`). 

In general, `online_market_total_value` is based on values extracted from the Hamilton County Auditor's online website and is preferred over `market_total_value` derived from historical building records maintained by CAGIS in `cagis_parcels`.
