# Property Code Enforcements Data

<!-- badges: start -->
[![latest github release for property_code_enforcements dpkg](https://img.shields.io/github/v/release/geomarker-io/parcel?sort=date&filter=property_code_enforcements-*&display_name=tag&label=%5B%E2%98%B0%5D&labelColor=%238CB4C3&color=%23396175)](https://github.com/geomarker-io/parcel/releases?q=property_code_enforcements&expanded=false)
<!-- badges: end -->

The `property_code_enforcements` data package contains the date, infraction description, infraction status, and address of reported infractions downloaded from the [code enforcement data](https://data.cincinnati-oh.gov/api/views/cncm-znd6/rows.csv?accessType=DOWNLOAD) from [CincyInsights](https://data.cincinnati-oh.gov/thriving-neighborhoods/Code-Enforcement/cncm-znd6). 

Infraction addresses were matched to known residential addresses and parcel identifiers in Hamilton County using [`addr`](https://github.com/cole-brokamp/addr). 

Infraction-level data were excluded if they (1) had a status of "Closed - No Violation", "Closed - No Violations Found", "Duplicate Case", or "Closed - Duplicate Complaint", or (2) did not contain a property address number/name.

There were 535,686 infractions reported between 1999-09-17 and 2024-08-09. 
- 335,077 (63%) were matched to a single residential address in Hamilton County and were matched to a parcel identifier.
- Note that in the case of condominiums, addresses are matched one-to-one, but are matched to multiple parcel identifiers. 
- The 850 (0.2%) infractions that were matched to more than one address and 199,759 (37%) that were not matched are missing parcel identifier.

#### Resources

- [City of Cincinnati code enforcement data dictionary](https://data.cincinnati-oh.gov/api/views/cncm-znd6/files/35440eee-1428-4bd9-9d98-a5935951dddf?download=true&filename=Code%20Enforcement%20-%203b.Data%20Dictionary.pdf) 
- [City of Cincinnati code enforcement guide](https://www.cincinnati-oh.gov/buildings/building-permit-forms-applications/application-forms/all-forms-handouts-checklists-alphabetical-list/code-enforcement-guide/) 
- [City of Cincinnati common housing code violations](https://www.cincinnati-oh.gov/buildings/building-permit-forms-applications/application-forms/all-forms-handouts-checklists-alphabetical-list/common-housing-code-violations/)