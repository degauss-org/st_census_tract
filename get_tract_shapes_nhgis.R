library(tidyverse)
library(sf)

year <- c('1970', '1980', '1990', '2000', '2010', '2020')
boundary_year <- c('2000', '2000', '2000', '2000', '2010', '2020')

all_tracts <- map(
  glue::glue('/Users/RASV5G/Downloads/nhgis0019_shape/nhgis0019_shapefile_tl{boundary_year}_us_tract_{year}/US_tract_{year}.shp'),
  st_read
)

all_tracts <- map2(all_tracts, year, ~.x %>% mutate(census_tract_vintage = .y))

all_tracts[[1]] <- all_tracts[[1]] %>%
  mutate(state_fips = stringr::str_sub(NHGISST, 1, 2),
         county_fips = stringr::str_sub(NHGISCTY, 1, 3),
         tract_fips = stringr::str_sub(GISJOIN2, 8, -1),
         census_tract_id = glue::glue('{state_fips}{county_fips}{tract_fips}')) %>%
  select(census_tract_vintage, census_tract_id)

all_tracts[[2]] <- all_tracts[[2]] %>%
  mutate(state_fips = stringr::str_sub(NHGISST, 1, 2),
         county_fips = stringr::str_sub(NHGISCTY, 1, 3),
         tract_fips = stringr::str_sub(GISJOIN2, 8, -1),
         census_tract_id = glue::glue('{state_fips}{county_fips}{tract_fips}')) %>%
  select(census_tract_vintage, census_tract_id)

all_tracts[[3]] <- all_tracts[[3]] %>%
  mutate(state_fips = stringr::str_sub(NHGISST, 1, 2),
         county_fips = stringr::str_sub(NHGISCTY, 1, 3),
         tract_fips = stringr::str_sub(GISJOIN2, 8, -1),
         census_tract_id = glue::glue('{state_fips}{county_fips}{tract_fips}')) %>%
  select(census_tract_vintage, census_tract_id)

all_tracts[[4]] <- all_tracts[[4]] %>%
  mutate(state_fips = stringr::str_sub(NHGISST, 1, 2),
         county_fips = stringr::str_sub(NHGISCTY, 1, 3),
         tract_fips = stringr::str_sub(GISJOIN2, 8, -1),
         census_tract_id = glue::glue('{state_fips}{county_fips}{tract_fips}')) %>%
  select(census_tract_vintage, census_tract_id)

all_tracts[[5]] <- all_tracts[[5]] %>%
  mutate(tract_fips = stringr::str_pad(TRACTCE10, 6, pad = "0"),
         census_tract_id = glue::glue('{STATEFP10}{COUNTYFP10}{tract_fips}')) %>%
  select(census_tract_vintage, census_tract_id)

all_tracts[[6]] <- all_tracts[[6]] %>%
  mutate(tract_fips = stringr::str_pad(TRACTCE, 6, pad = "0"),
         census_tract_id = glue::glue('{STATEFP}{COUNTYFP}{tract_fips}')) %>%
  select(census_tract_vintage, census_tract_id)

all_tracts <- map(all_tracts, ~st_transform(.x, 5072))
all_tracts <- purrr::map(all_tracts, st_make_valid)
all_tracts <- map(all_tracts, ~dplyr::select(.x, -census_tract_vintage))

names(all_tracts) <- year

saveRDS(all_tracts, 'census_tracts_1970_to_2020_valid.rds')

