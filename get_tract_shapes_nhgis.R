library(tidyverse)
library(sf)

year <- c('1970', '1980', '1990', '2000', '2010', '2020')
boundary_year <- c('2000', '2000', '2000', '2000', '2010', '2020')

all_tracts <- map(
  glue::glue('nhgis0019_shape/nhgis0019_shapefile_tl{boundary_year}_us_tract_{year}/US_tract_{year}.shp'),
  st_read
)

all_tracts <- map2(all_tracts, year, ~.x %>% mutate(census_tract_vintage = .y))

all_tracts <- bind_rows(all_tracts) %>%
  select(census_tract_vintage, GISJOIN2, GEOID10, GEOID) %>%
  mutate(census_tract_id = case_when(
    census_tract_vintage %in% c('1970', '1980', '1990', '2000') ~ GISJOIN2,
    census_tract_vintage == '2010' ~ GEOID10,
    census_tract_vintage == '2020' ~ GEOID
  )) %>%
  select(census_tract_vintage, census_tract_id)

all_tracts <- st_transform(all_tracts, 5072)

all_tracts <- split(all_tracts, f = all_tracts$census_tract_vintage)
all_tracts <- map(all_tracts, ~dplyr::select(.x, -census_tract_vintage))

saveRDS(all_tracts, 'census_tracts_1970_to_2020.rds')
