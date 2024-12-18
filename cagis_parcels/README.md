# CAGIS Parcels Data

<!-- badges: start -->
[![latest github release for cagis_parcels dpkg](https://img.shields.io/github/v/release/geomarker-io/parcel?sort=date&filter=cagis_parcels-*&display_name=tag&label=%5B%E2%98%B0%5D&labelColor=%238CB4C3&color=%23396175)](https://github.com/geomarker-io/parcel/releases?q=cagis_parcels&expanded=false)
<!-- badges: end -->

The `cagis_parcels` tabular-data-resource contains parcel identifiers, parcel addresses, and parcel characteristics downloaded from the [Cincinnati Area Geographic Information System (CAGIS)](https://cagismaps.hamilton-co.org/cagisportal/mapdata/download).

Auditor parcel-level data were excluded if they (1) did not contain a parcel identifier, (2) did not contain a property address number/name, or (3) had a duplicated parcel identifier.

Parcels with the following land use categories are included in the data resource and others are excluded.
These were selected to reflect *residential* usages of parcels.

| land_use                       |
|:------------------------------:|
| single family dwelling         |
| condominium unit               |
| two family dwelling            |
| apartment, 4-19 units          |
| landominium                    |
| three family dwelling          |
| condo or pud garage            |
| other residential structure    |
| metropolitan housing authority |
| apartment, 40+ units           |
| apartment, 20-39 units         |
| manufactured home              |
| office / apartment over        |
| boataminium                    |
| other commercial housing       |
| mobile home / trailer park     |
| lihtc res                      |

Some of the parcel characteristics do not make sense in certain contexts and should not be interpreted incorrectly; for example, the value of a parcel for a multi-family or multi-unit housing structure shouldn’t be compared to the value of a parcel for a single-family household for the purposes of assesing individual-level SES.
