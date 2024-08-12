# parcel

> Older versions of this repository contain an R package that relies on the usaddress and dedupe python libraries for address matching. Consider using the {[addr](https://github.com/cole-brokamp/addr)} R package instead for more precise and accurate matching to CAGIS parcel identifiers (and fewer dependencies).

This repository contains data packages: `cagis_parcels`, `auditor_online_parcels`, `property_code_enforcements`.

## Parcel Identifiers and Corresponding Parcel Addresses

A `parcel_id` refers to the Hamilton County Auditor’s “Parcel Number”, which is referred to as the “Property Number” within the CAGIS Open Data and uniquely identifies properties.
In rare cases, multple addresses can share the same parcel boundaries, but have unique `parcel_id`s and in these cases, their resulting centroid coordinates would also be identical.

Within the process of matching to a parcel, an individual address could be merged with differing types and resolutions of data:

``` mermaid
%%{init: { "fontFamily": "arial" } }%%

flowchart LR
classDef id fill:#fff,stroke:#000,stroke-width:1px;
classDef tool fill:#e8e8e8,stroke:#000,stroke-width:1px,stroke-dasharray: 5 2;
classDef data fill:#fff,stroke:#000,stroke-width:1px;

addr(hospitalization):::id ---> hc("likely in \nHamilton County \n (by ZIP code)"):::data
addr ---> nhc("not in Hamilton  County"):::tool

hc --> inst[institutional parcel]:::id
inst -. "institution 'type' linkage\n (e.g., JFS, CCHMC, RMH)" .-> sdoh("temporary housing,\n foster care,\n low income housing tax credit"):::data

hc --> res(residential parcel):::id

res -- CCHMC \nlinkage --> hhh("home's hospitalization history \n (i.e., pedigree)"):::data
res -- CAGIS & \nODC linkage --> hce(housing code enforcement,\n public service calls, crime):::data

res -- single family dwelling --> vat("family-level SES measures \n (e.g., value, age, condition, tenure)"):::data
res -- multi-family dwelling --> lu("auditor land use type \n (e.g., two family dwelling, \n apartment with 20-39 units)"):::data

hc --> npm(not matched \nto a parcel):::tool
```

### Condominiums

Because “second line” address components (e.g., “Unit 2B”) are not captured, a single address can refer to multiple parcels in the case of condos or otherwise shared building ownership.
For example, the address “323 Fifth St” has six distinct `parcel_id`s, each with different home values and land uses:

| parcel_id   | market_total_value | land_use                    |
|:------------|-------------------:|:----------------------------|
| 14500010321 |             397500 | condominium unit            |
| 14500010317 |             123000 | condominium office building |
| 14500010320 |             180000 | condominium unit            |
| 14500010319 |             255000 | condominium unit            |
| 14500010322 |             388230 | condominium unit            |
| 14500010318 |             239500 | condominium unit            |

### Large Apartment Complexes

Large apartment complexes often use multiple mailing addresses that are not the same as the parcel address(es). 

## Estimating the number of households per parcel

Certain calculations needs to be weighted by households instead of
parcel; e.g. “What fraction of families live near roadway in Avondale?”.
We assume the following as a conservative estimate of the number of
households per parcel for each `land_use` code:

| `land_use`                      | n households |
|:--------------------------------|-------------:|
| single family dwelling          |            1 |
| condominium unit                |            1 |
| two family dwelling             |            2 |
| three family dwelling           |            3 |
| apartment, 4-19 units           |            4 |
| apartment, 20-39 units          |           20 |
| apartment, 40+ units            |           40 |
| landominium                     |            1 |
| charities, hospitals, retir     |            1 |
| condo or pud garage             |            1 |
| metropolitan housing authority  |            1 |
| office / apartment over         |            1 |
| manufactured home               |            1 |
| other commercial housing        |            1 |
| nursing home / private hospital |            1 |
| mobile home / trailer park      |            1 |
| single fam dw 0-9 acr           |            1 |
| independent living (seniors)    |            1 |
| lihtc res                       |            1 |
| condominium office building     |            0 |
| other residential structure     |            0 |
| boataminium                     |            0 |


