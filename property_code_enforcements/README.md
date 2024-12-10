# Property Code Enforcements Data

<!-- badges: start -->
[![latest github release for property_code_enforcements dpkg](https://img.shields.io/github/v/release/geomarker-io/parcel?sort=date&filter=property_code_enforcements-*&display_name=tag&label=%5B%E2%98%B0%5D&labelColor=%238CB4C3&color=%23396175)](https://github.com/geomarker-io/parcel/releases?q=property_code_enforcements&expanded=false)
<!-- badges: end -->

The `property_code_enforcements` data package contains the date, infraction description, infraction status, and address of reported infractions downloaded from the [code enforcement data](https://data.cincinnati-oh.gov/api/views/cncm-znd6/rows.csv?accessType=DOWNLOAD) from [CincyInsights](https://data.cincinnati-oh.gov/thriving-neighborhoods/Code-Enforcement/cncm-znd6). 

Infraction addresses were matched to known residential addresses and parcel identifiers in Hamilton County using [`addr`](https://github.com/cole-brokamp/addr). ZIP codes were assigned using jittered coordinates provided in the source data, then addresses were matched nested by ZIP code. Addresses that were not matched to any known address in Hamilton County were then attempted to match within the entire county. 

Infraction-level data were excluded if they (1) had a status of "Closed - No Violation", "Closed - No Violations Found", "Duplicate Case", or "Closed - Duplicate Complaint", or (2) did not contain a property address number/name.

There were 540,508 infractions reported between 1999-09-17 and 2024-12-08. 
- 330,338 (61%) were matched to a residential address in Hamilton County with a parcel identifier.
- Note that in the case of condominiums, addresses are matched one-to-one, but more than one parcel identifier. Here we randomly select one parcel identifier. 
- 210,170 (39%) were not matched and are missing parcel identifier

`property_code_enforcements` fields include
- `id`: the infraction identifier
- `date`: the date the infraction was reported
- `description`: a text description of the infraction
- `status`: the infraction status
- `lat_jittered` and `lon_jittered`: randomly skewed coordinates (represent the same block area, but not the exact location, of the infraction)
- `addr`: the property address of the infraction as an `addr` object
- `cagis_addr`: the matched `addr` when matched to `addr::cagis_addr()`
- `cagis_parcel_id`: parcel identifier from `addr::cagis_addr()`

#### Resources

- [City of Cincinnati code enforcement data dictionary](https://data.cincinnati-oh.gov/api/views/cncm-znd6/files/35440eee-1428-4bd9-9d98-a5935951dddf?download=true&filename=Code%20Enforcement%20-%203b.Data%20Dictionary.pdf) 
- [City of Cincinnati code enforcement guide](https://www.cincinnati-oh.gov/buildings/building-permit-forms-applications/application-forms/all-forms-handouts-checklists-alphabetical-list/code-enforcement-guide/) 
- [City of Cincinnati common housing code violations](https://www.cincinnati-oh.gov/buildings/building-permit-forms-applications/application-forms/all-forms-handouts-checklists-alphabetical-list/common-housing-code-violations/)
