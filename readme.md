# st_census_tract <a href='https://degauss.org'><img src='https://github.com/degauss-org/degauss_hex_logo/raw/main/PNG/degauss_hex.png' align='right' height='138.5' /></a>

[![](https://img.shields.io/github/v/release/degauss-org/st_census_tract?color=469FC2&label=version&sort=semver)](https://github.com/degauss-org/st_census_tract/releases)
[![container build status](https://github.com/degauss-org/st_census_tract/workflows/build-deploy-release/badge.svg)](https://github.com/degauss-org/st_census_tract/actions/workflows/build-deploy-release.yaml)

## Using

If `my_address_file_geocoded.csv` is a file in the current working directory with coordinate columns named `lat`, `lon`, `start_date`, and `end_date`, then the [DeGAUSS command](https://degauss.org/using_degauss.html#DeGAUSS_Commands):

```sh
docker run --rm -v $PWD:/tmp ghcr.io/degauss-org/st_census_tract:0.2.1 my_address_file_geocoded.csv
```

will produce `my_address_file_geocoded_st_census_tract_0.2.1.csv` with added columns:

- **`census_tract_vintage`**: decennial census year 
- **`census_tract_id`**: census tract FIPS identifier 

*Block Group identifiers are defined as the concatenation of the state, county, tract, and block group fips identifiers (commonly called GISJOIN or GEOID in census data). All census tract identifiers are 11 digits and all census block group identifiers are 12 digits, with the exception of some 1990, 1980, and 1970 tracts that are 9 digits, resulting in 10 digit block group identifiers.*

## Geomarker Methods

Input data must have columns called `lat` and `lon` containing the latitude and longitude, respecitvely, as well as `start_date` and `end_date` specifying a date range over which tract-level geomarkers will be assessed. The date range will be used to assign a census tract vintage, ranging from 1970 to 2020 by decade. If you do not have temporal data and wish to use the 2010 tract or block group boundaries, you can utilize the [census_block_group](https://degauss.org/census_block_group) DeGAUSS container. 

After the vintage is assigned, the latitude and longitude will be overlayed within a tract to assign a census tract identifier from the appropriate decade.

If the date range spans two census decades, the result will contain one row per decade. For example, 

| id | lat | lon | start_date | end_date |
|---:|----:|----:|------------|----------|
|1234| 39.15852 | -84.41757 | 2019-12-27	| 2020-01-03	|

would become

| id | lat | lon | start_date | end_date | census_tract_vintage | census_tract_id |
|---:|----:|----:|------------|----------|------------:|----------:|
|1234| 39.15852 | -84.41757 | **2019-12-27**	| **2019-12-31**	| 2010 | 39061005400 |
|1234| 39.15852 | -84.41757 | **2020-01-01**	| **2020-01-03**	| 2020 | 39061027600 |

where a 2010 tract identifier is assigned to the first row, and a 2020 tract identifier is assigned to the second row.

## Geomarker Data

- census tract boundaries were obtained from [NHGIS](https://www.nhgis.org/) and transformed to crs 5072
- census tract boundaries used in this container are stored at [`s3://geomarker/geometries/census_tracts_1970_to_2020_valid.rds`](https://geomarker.s3.us-east-2.amazonaws.com/geometries/census_tracts_1970_to_2020_valid.rds)

## DeGAUSS Details

For detailed documentation on DeGAUSS, including general usage and installation, please see the [DeGAUSS homepage](https://degauss.org).
