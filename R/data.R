#' CAGIS parcels
#' 
#' A curated property-level data resource derived from the Hamilton County, OH Auditor data distributed through CAGIS Open Data. See `data-raw/tabular-data-resource.yaml` for detailed metadata.
#' @source Cincinnati Area Geographic Information System (CAGIS: https://cagismaps.hamilton-co.org/cagisportal/mapdata/download)
"cagis_parcels"

#' CAGIS hashdresses
#'
#' The parcel identifiers and a property address (consisting of
#' property_addr_number, property_addr_street, property_addr_suffix)
#' for each parcel are `hashdress()`ed using the parsed street number and street name.
#' This object is used to match parcel identifiers
#' to hashdresses computed on other, real-world addresses. Note that
#' the five digit ZIP code is not included in CAGIS data, and wasn't used to
#' compute the hashdress.  These hashdresses are specific to Hamilton
#' County, OH.
"cagis_hashdresses"
