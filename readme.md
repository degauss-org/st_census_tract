# st_census_tract <a href='https://degauss.org'><img src='https://github.com/degauss-org/degauss_template/raw/master/DeGAUSS_hex.png' align='right' height='138.5' /></a>

> link geocoded coordinates with date ranges to cooresponding census tracts from the appropriate vintage
[![](https://img.shields.io/github/v/tag/degauss-org/st_census_tract)](https://github.com/degauss-org/st_census_tract/releases)

## DeGAUSS example call

If `my_address_file_geocoded.csv` is a file in the current working directory with coordinate columns named `lat` and `lon`, then

```sh
docker run --rm -v $PWD:/tmp ghcr.io/degauss-org/st_census_tract:0.1.2 my_address_file_geocoded.csv
```

will produce `my_address_file_geocoded_st_census_tract_v0.1.2.csv` with added columns named `census_tract_vintage` and `census_tract_id`. 

## geomarker methods

Input data must have columns called `lat` and `lon` containing the latitude and longitude, respecitvely, as well as `start_date` and `end_date` specifying a date range over which tract-level geomarkers will be assessed. The date range will be used to assign a census tract vintage, ranging from 1970 to 2020 by decade. If you do not have temporal data and wish to use the 2010 tract or block group boundaries, you can utilize the [census_block_group](https://degauss.org/census_block_group) DeGAUSS container. 

After the vintage is assigned, the latitude and longitude will be overlayed within a tract to assign a census tract identifier from the appropriate decade.

If the date range spans two census decades, the result will contain one row per decade. For example, 

| id | lat | lon | start_date | end_date |
|---:|----:|----:|------------|----------|
|1234| 39.15852 | -84.41757 | 2019-12-27	| 2020-01-03	|

would become

| id | lat | lon | start_date | end_date | census_tract_vintage | census_tract_id |
|---:|----:|----:|------------|----------|------------:|----------:|
|1234| 39.15852 | -84.41757 | **2019-12-27**	| **2019-12-31**	| 2019 | 39061005400 |
|1234| 39.15852 | -84.41757 | **2020-01-01**	| **2020-01-03**	| 2020 | 39061027600 |

where a 2019 tract identifier is assigned to the first row, and a 2020 tract identifier is assigned to the second row.

## geomarker data

- census tract boundaries were obtained from [NHGIS](https://www.nhgis.org/) and transformed to crs 5072
- census tract boundaries used in this container are stored at [`s3://geomarker/geometries/census_tracts_1970_to_2020_valid.rds`](https://geomarker.s3.us-east-2.amazonaws.com/geometries/census_tracts_1970_to_2020_valid.rds)

## DeGAUSS details

For detailed documentation on DeGAUSS, including general usage and installation, please see the [DeGAUSS homepage](https://degauss.org).
