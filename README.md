
<!-- README.md is generated from README.Rmd. Please edit that file -->

# parcel

<!-- badges: start -->

[![R-CMD-check](https://github.com/geomarker-io/parcel/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/geomarker-io/parcel/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of parcel is to provide tools for matching real-world addresses
to reference sets of addresses; e.g., “352 Helen Street”, “352 Helen
St.” or “352 helen st”. This package is motivated by the included
example data resources of auditor parcel tax data from Hamilton County,
Ohio.

With this specific goal in mind, parcel includes:

- functions for cleaning and tagging components of addresses:
  **`clean_address()`**, **`tag_address()`**, and
  **`create_address_stub()`**
- the `cagis_parcels` tabular-data-resource, which contains parcel
  identifiers, parcel addresses, and parcel characteristics downloaded
  from the [Cincinnati Area Geographic Information System
  (CAGIS)](https://cagismaps.hamilton-co.org/cagisportal/mapdata/download)
- the `hamilton_online_parcels` tabular-data-resource, which contains
  parcel characteristics scraped from [Hamilton County Auditor
  Online](https://wedge1.hcauditor.org/)
- functions for joining addresses to parcel identifiers based on an
  included model pretrained on electronic health record addresses in
  Hamilton County, OH: **`link_parcel()`**

## Installation

{parcel} requires the `usaddress` python module for tagging addresses
and creating address stubs, as well as the `dedupe` and
`dedupe-variable-address` python modules for matching addresses, all of
which can be installed from inside R with:

``` r
reticulate::py_install("usaddress", pip = TRUE)
reticulate::py_install("dedupe", pip = TRUE)
reticulate::py_install("dedupe-variable-address", pip = TRUE)
```

The development version of parcel can be installed with:

``` r
pak::pak("geomarker-io/parcel")
```

## Example Usage

Use `get_parcel_data()` to get the corresponding parcel data for a
vector of addresses:

``` r
library(parcel)
get_parcel_data(c("1069 Overlook Avenue Cincinnati OH 45238",
                  "419 Elm St. Cincinnati OH 45238",
                  "3544 Linwood Av Cincinnati OH 45226"))
#> # A tibble: 3 × 23
#>   input_address              parcel_id score parcel_address property_addr_number
#>   <chr>                      <chr>     <dbl> <chr>          <chr>               
#> 1 1069 Overlook Avenue Cinc… 1800A800… 0.717 1069 OVERLOOK… 1069                
#> 2 419 Elm St. Cincinnati OH… 54000410… 0.733 419 ELM ST     419                 
#> 3 3544 Linwood Av Cincinnat… 01900010… 0.733 3544 LINWOOD … 3544                
#> # ℹ 18 more variables: property_addr_street <chr>, property_addr_suffix <chr>,
#> #   condo_id <chr>, condo_unit <chr>, parcel_centroid_lat <dbl>,
#> #   parcel_centroid_lon <dbl>, market_total_value <dbl>, land_use <fct>,
#> #   acreage <dbl>, homestead <lgl>, rental_registration <lgl>,
#> #   RED_25_FLAG <lgl>, year_built <int>, n_total_rooms <int>, n_bedrooms <int>,
#> #   n_full_bathrooms <int>, n_half_bathrooms <int>,
#> #   online_market_total_value <dbl>
```

## Python, `miniconda`, and `virtualenv`

`reticulate::py_install()` assumes a non-system version of Python is
already installed and will offer to install Miniconda and create an
environment specifically for R and the reticulate package.

As an alternative to miniconda, it is possible to create a virtualenv
using reticulate:

``` r
library(reticulate)
install_python("3.9.12")
virtualenv_create("r-parcel", version = "3.9.12")
use_virtualenv("r-parcel")
py_install("usaddress", pip = TRUE)
py_module_available("usaddress")
```

To help R find this virtualenv for every session, either
`use_virtualenv("r-parcel")` should be run in every R session *or*,
better yet, by setting the `RETICULATE_PYTHON` environment variable in a
user- or project-specific `.Renviron` file. You can check on which
python installation chosen to be used by reticulate and why by using:

``` r
reticulate::py_config()
reticulate::py_list_packages()
```

## CAGIS Parcels Data

The `cagis_parcels` tabular data resource (TDR) is created using the R
scripts in `/inst` and stored within the package. It can be loaded using
{[`codec`](https://geomarker.io/codec)}:

``` r
d_parcel <- codec::read_tdr_csv(fs::path_package("parcel", "cagis_parcels"))

head(d_parcel)
#> # A tibble: 6 × 15
#>   parcel_id     parcel_address       property_addr_number property_addr_street
#>   <chr>         <chr>                <chr>                <chr>               
#> 1 6210024007000 210 CARRINGTON PL    210                  CARRINGTON          
#> 2 6210024009200 220 CARRINGTON PL    220                  CARRINGTON          
#> 3 6210024007100 210 CARRINGTON PL    210                  CARRINGTON          
#> 4 6210024008200 220 CARRINGTON PL    220                  CARRINGTON          
#> 5 5000122021500 8053 WITTS MILL LN   8053                 WITTS MILL          
#> 6 5000122020900 8120 WITTS MEADOW LN 8120                 WITTS MEADOW        
#> # ℹ 11 more variables: property_addr_suffix <chr>, condo_id <chr>,
#> #   condo_unit <chr>, parcel_centroid_lat <dbl>, parcel_centroid_lon <dbl>,
#> #   market_total_value <dbl>, land_use <fct>, acreage <dbl>, homestead <lgl>,
#> #   rental_registration <lgl>, RED_25_FLAG <lgl>

# without codec:
# read.csv(fs::path_package("parcel", "cagis_parcels"))
```

``` r
options(knitr.kable.NA = '')
codec::glimpse_attr(d_parcel) |>
  knitr::kable()
```

| name        | value                                                                                                                                                                                          |
|:------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| profile     | tabular-data-resource                                                                                                                                                                          |
| name        | cagis_parcels                                                                                                                                                                                  |
| path        | cagis_parcels.csv                                                                                                                                                                              |
| version     | 0.8.2                                                                                                                                                                                          |
| title       | CAGIS Parcels                                                                                                                                                                                  |
| homepage    | <https://github.com/geomarker-io/hamilton_parcels>                                                                                                                                             |
| description | A curated property-level data resource derived from the Hamilton County, OH Auditor data distributed through CAGIS Open Data: <https://cagismaps.hamilton-co.org/cagisportal/mapdata/download> |

``` r
options(knitr.kable.NA = '')
codec::glimpse_schema(d_parcel) |>
  knitr::kable()
```

| name                 | title                     | description                                                    | type    | constraints                                                                                                                                                                                                                                                                                                                                                                        |
|:---------------------|:--------------------------|:---------------------------------------------------------------|:--------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| parcel_id            | Parcel Identifier         | uniquely identifies properties; the auditor Parcel Number      | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| parcel_address       | Parcel Address            | derived by pasting Property Address Number, Street, and Suffix | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| property_addr_number | Address Number            |                                                                | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| property_addr_street | Address Street            |                                                                | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| property_addr_suffix | Address Suffix            |                                                                | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| condo_id             | Condo identifier          | used to match two parcels to the same building of condos       | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| condo_unit           | Condo unit                | specifies a specific unit within a building of condos          | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| parcel_centroid_lat  | Parcel Centroid Latitude  | coordinates derived from centroid of parcel shape              | number  |                                                                                                                                                                                                                                                                                                                                                                                    |
| parcel_centroid_lon  | Parcel Centroid Longitude | coordinates derived from centroid of parcel shape              | number  |                                                                                                                                                                                                                                                                                                                                                                                    |
| market_total_value   | Market Total Value        |                                                                | number  |                                                                                                                                                                                                                                                                                                                                                                                    |
| land_use             |                           |                                                                | string  | apartment, 4-19 units, apartment, 20-39 units, apartment, 40+ units, mobile home / trailer park, other commercial housing, office / apartment over, single family dwelling, two family dwelling, three family dwelling, condominium unit, boataminium, condo or pud garage, landominium, manufactured home, lihtc res, other residential structure, metropolitan housing authority |
| acreage              | Acreage                   |                                                                | number  |                                                                                                                                                                                                                                                                                                                                                                                    |
| homestead            | Homestead                 |                                                                | boolean |                                                                                                                                                                                                                                                                                                                                                                                    |
| rental_registration  | Rental Registration       |                                                                | boolean |                                                                                                                                                                                                                                                                                                                                                                                    |
| RED_25_FLAG          |                           |                                                                | boolean |                                                                                                                                                                                                                                                                                                                                                                                    |

Some of the parcel characteristics do not make sense in certain contexts
and should not be interpreted incorrectly; for example, the value of a
parcel for a multi-family or multi-unit housing structure shouldn’t be
compared to the value of a parcel for a single-family household for the
purposes of assesing individual-level SES. Within the process of
matching to a parcel, an individual address could be merged with
differing types and resolutions of data:

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

## Hamilton County Auditor Online Data

The `hamilton_online_parcels` TDR is created by linking a saved scraping
of the [auditor’s website](https://wedge1.hcauditor.org/) to the parcel
identifiers in the `cagis_parcels` TDR.

Similarly, the `hamilton_online_parcel` TDR is created using the R
scripts in `/inst` and stored within the package. It can be loaded using
{[`codec`](https://geomarker.io/codec)}:

``` r
d_online <- codec::read_tdr_csv(fs::path_package("parcel", "hamilton_online_parcels"))

head(d_online)
#> # A tibble: 6 × 7
#>   parcel_id     year_built n_total_rooms n_bedrooms n_full_bathrooms
#>   <chr>              <int>         <int>      <int>            <int>
#> 1 6210024007000       1961             8          3                2
#> 2 6210024009200       1960             7          3                3
#> 3 6210024007100       1960             7          3                2
#> 4 6210024008200       1960             7          3                2
#> 5 5000122021500       1955             6          2                1
#> 6 5000122020900       1955             6          3                2
#> # ℹ 2 more variables: n_half_bathrooms <int>, online_market_total_value <dbl>

# without codec:
# read.csv(fs::path_package("parcel", "hamilton_online_parcels"))
```

``` r
options(knitr.kable.NA = '')
codec::glimpse_attr(d_online) |>
  knitr::kable()
```

| name        | value                                                                                                                                                                                                                           |
|:------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| profile     | tabular-data-resource                                                                                                                                                                                                           |
| name        | hamilton_online_parcels                                                                                                                                                                                                         |
| path        | hamilton_online_parcels.csv                                                                                                                                                                                                     |
| version     | 0.8.2                                                                                                                                                                                                                           |
| title       | Hamilton Online Parcels                                                                                                                                                                                                         |
| homepage    | <https://github.com/geomarker-io/parcel>                                                                                                                                                                                        |
| description | A curated property-level data resource derived from scraping the Hamilton County, OH Auditor Online: <https://wedge1.hcauditor.org/>. Data was scraped for only residential parcels in CAGIS Parcels; see homepage for details. |

``` r
options(knitr.kable.NA = '')
codec::glimpse_schema(d_parcel) |>
  knitr::kable()
```

| name                 | title                     | description                                                    | type    | constraints                                                                                                                                                                                                                                                                                                                                                                        |
|:---------------------|:--------------------------|:---------------------------------------------------------------|:--------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| parcel_id            | Parcel Identifier         | uniquely identifies properties; the auditor Parcel Number      | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| parcel_address       | Parcel Address            | derived by pasting Property Address Number, Street, and Suffix | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| property_addr_number | Address Number            |                                                                | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| property_addr_street | Address Street            |                                                                | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| property_addr_suffix | Address Suffix            |                                                                | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| condo_id             | Condo identifier          | used to match two parcels to the same building of condos       | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| condo_unit           | Condo unit                | specifies a specific unit within a building of condos          | string  |                                                                                                                                                                                                                                                                                                                                                                                    |
| parcel_centroid_lat  | Parcel Centroid Latitude  | coordinates derived from centroid of parcel shape              | number  |                                                                                                                                                                                                                                                                                                                                                                                    |
| parcel_centroid_lon  | Parcel Centroid Longitude | coordinates derived from centroid of parcel shape              | number  |                                                                                                                                                                                                                                                                                                                                                                                    |
| market_total_value   | Market Total Value        |                                                                | number  |                                                                                                                                                                                                                                                                                                                                                                                    |
| land_use             |                           |                                                                | string  | apartment, 4-19 units, apartment, 20-39 units, apartment, 40+ units, mobile home / trailer park, other commercial housing, office / apartment over, single family dwelling, two family dwelling, three family dwelling, condominium unit, boataminium, condo or pud garage, landominium, manufactured home, lihtc res, other residential structure, metropolitan housing authority |
| acreage              | Acreage                   |                                                                | number  |                                                                                                                                                                                                                                                                                                                                                                                    |
| homestead            | Homestead                 |                                                                | boolean |                                                                                                                                                                                                                                                                                                                                                                                    |
| rental_registration  | Rental Registration       |                                                                | boolean |                                                                                                                                                                                                                                                                                                                                                                                    |
| RED_25_FLAG          |                           |                                                                | boolean |                                                                                                                                                                                                                                                                                                                                                                                    |

## Inclusion/Exclusion Criteria for Parcel Data

Auditor parcel-level data were excluded if they (1) did not contain a
parcel identifier, (2) did not contain a property address number/name,
or (3) had a duplicated parcel identifier.

Parcels with the following land use categories are included in the data
resource and others are excluded. These were selected to reflect
*residential* usages of parcels.

``` r
library(dplyr, warn.conflicts = FALSE)

d_parcel |>
  group_by(land_use) |>
  summarize(n_parcels = n()) |>
  arrange(desc(n_parcels)) |>
  knitr::kable()
```

| land_use                       | n_parcels |
|:-------------------------------|----------:|
| single family dwelling         |    213044 |
| condominium unit               |     19754 |
| two family dwelling            |     11352 |
| apartment, 4-19 units          |      5659 |
| landominium                    |      3047 |
| three family dwelling          |      1863 |
| condo or pud garage            |      1063 |
| other residential structure    |       875 |
| metropolitan housing authority |       744 |
| apartment, 40+ units           |       625 |
| apartment, 20-39 units         |       457 |
| manufactured home              |       204 |
| office / apartment over        |       188 |
| boataminium                    |       141 |
| other commercial housing       |        99 |
| mobile home / trailer park     |        40 |
| lihtc res                      |        25 |

## Non-Residential Parcels

Known non-residential addresses will be matched and returned with a
special parcel identifer denoting that the matched parcel is
non-residential; e.g., Cincinnati Children’s Hospital Medical Center,
Jobs and Family Services, Ronald McDonald House):

``` r
c("222 E Central Parkway Cincinnati Ohio 45220",
  "3333 Burnet Ave Cincinnati Ohio 45219",
  "3333 Burnet Avenue Cincinnati Ohio 45219",
  "350 Erkenbrecher Ave Cincinnati Ohio 45219") |>
  get_parcel_data()
#> # A tibble: 4 × 23
#>   input_address              parcel_id score parcel_address property_addr_number
#>   <chr>                      <chr>     <dbl> <chr>          <chr>               
#> 1 222 E Central Parkway Cin… nonres-j… 0.620 <NA>           <NA>                
#> 2 3333 Burnet Ave Cincinnat… nonres-c… 0.733 <NA>           <NA>                
#> 3 3333 Burnet Avenue Cincin… nonres-c… 0.720 <NA>           <NA>                
#> 4 350 Erkenbrecher Ave Cinc… nonres-r… 0.733 <NA>           <NA>                
#> # ℹ 18 more variables: property_addr_street <chr>, property_addr_suffix <chr>,
#> #   condo_id <chr>, condo_unit <chr>, parcel_centroid_lat <dbl>,
#> #   parcel_centroid_lon <dbl>, market_total_value <dbl>, land_use <fct>,
#> #   acreage <dbl>, homestead <lgl>, rental_registration <lgl>,
#> #   RED_25_FLAG <lgl>, year_built <int>, n_total_rooms <int>, n_bedrooms <int>,
#> #   n_full_bathrooms <int>, n_half_bathrooms <int>,
#> #   online_market_total_value <dbl>
```

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

## Identifiers for Parcels and Properties

A `parcel_id` refers to the Hamilton County Auditor’s “Parcel Number”,
which is referred to as the “Property Number” within the CAGIS Open Data
and uniquely identifies properties. In rare cases, multple addresses can
share the same parcel boundaries, but have unique `parcel_id`s and in
these cases, their resulting centroid coordinates would also be
identical.

Because “second line” address components (e.g., “Unit 2B”) are not
captured, a single address can refer to multiple parcels in the case of
condos or otherwise shared building ownership. For example, the address
“323 Fifth St” has six distinct `parcel_id`s, each with different home
values and land uses:

| parcel_id   | market_total_value | land_use                    |
|:------------|-------------------:|:----------------------------|
| 14500010321 |             397500 | condominium unit            |
| 14500010317 |             123000 | condominium office building |
| 14500010320 |             180000 | condominium unit            |
| 14500010319 |             255000 | condominium unit            |
| 14500010322 |             388230 | condominium unit            |
| 14500010318 |             239500 | condominium unit            |

In this case, a special parcel identifier `TIED_MATCH` is returned to
denote that the address matched more than one parcel:

``` r
get_parcel_data("323 Fifth St W Cincinnati OH 45202")
#> # A tibble: 1 × 23
#>   input_address              parcel_id score parcel_address property_addr_number
#>   <chr>                      <chr>     <dbl> <chr>          <chr>               
#> 1 323 Fifth St W Cincinnati… TIED_MAT… 0.733 <NA>           <NA>                
#> # ℹ 18 more variables: property_addr_street <chr>, property_addr_suffix <chr>,
#> #   condo_id <chr>, condo_unit <chr>, parcel_centroid_lat <dbl>,
#> #   parcel_centroid_lon <dbl>, market_total_value <dbl>, land_use <fct>,
#> #   acreage <dbl>, homestead <lgl>, rental_registration <lgl>,
#> #   RED_25_FLAG <lgl>, year_built <int>, n_total_rooms <int>, n_bedrooms <int>,
#> #   n_full_bathrooms <int>, n_half_bathrooms <int>,
#> #   online_market_total_value <dbl>
```
