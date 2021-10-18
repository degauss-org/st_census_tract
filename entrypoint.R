#!/usr/local/bin/Rscript

dht::greeting(geomarker_name = 'Spatiotemporal Census Tract', 
              version = '0.0.3', 
              description = 'links geocoded coordinates with date ranges to cooresponding census tracts from the appropriate vintage')

old_warn <- getOption("warn")
options(warn = -1)

library(dht)
qlibrary(readr)
qlibrary(dplyr)
qlibrary(tidyr)
qlibrary(sf)

options(warn = old_warn)

doc <- '
      Usage:
      entrypoint.R <filename>
      '

opt <- docopt::docopt(doc)
## for interactive testing
## opt <- docopt::docopt(doc, args = 'test/my_address_file_geocoded.csv')

message('reading input file...')
raw_data <- readr::read_csv(opt$filename)

dht::check_for_column(raw_data, 'lat', raw_data$lat)
dht::check_for_column(raw_data, 'lon', raw_data$lon)
dht::check_for_column(raw_data, 'start_date', raw_data$start_date)
dht::check_for_column(raw_data, 'end_date', raw_data$end_date)
raw_data$start_date <- dht::check_dates(raw_data$start_date)
raw_data$end_date <- dht::check_dates(raw_data$end_date)
dht::check_end_after_start_date(raw_data$start_date, raw_data$end_date)

raw_data$.row <- seq_len(nrow(raw_data))

d <-
  raw_data %>%
  select(.row, lat, lon, start_date, end_date) %>%
  na.omit() 

message('determining census decade for each date range...')
d <- d %>% 
  mutate(start_year = glue::glue('{floor(lubridate::year(start_date) / 10)}0'), 
         end_year = glue::glue('{floor(lubridate::year(end_date) / 10)}0'))

cli::cli_alert_warning('{nrow(d %>% filter(start_year != end_year) )} date range{?s} span{?s/} more than one census decade and will be split to one row per decade.')

d_splits <- d %>% 
  filter(start_year != end_year) %>% 
  mutate(new_dates = list(data.frame(new_start_date = c(start_date, 
                                                        glue::glue("{lubridate::year(end_date)}-01-01")), 
                                     new_end_date = c(as.Date(glue::glue("{lubridate::year(start_date)}-12-31")), 
                                                      end_date)))) %>% 
  unnest(cols = c(new_dates)) %>% 
  mutate(start_year = glue::glue('{floor(lubridate::year(new_start_date) / 10)}0'), 
         end_year = glue::glue('{floor(lubridate::year(new_end_date) / 10)}0')) %>% 
  select(-start_date, -end_date, 
         start_date = new_start_date, 
         end_date = new_end_date)

d <- bind_rows(d %>% filter(start_year == end_year), d_splits) %>% 
  mutate(census_tract_vintage = start_year) %>% 
  select(-start_year, -end_year) 

d <- d %>%
  group_by(lat, lon) %>%
  nest(.rows = c(.row)) %>%
  st_as_sf(coords = c('lon', 'lat'), crs = 4326) %>% 
  st_transform(5072)

d <- d %>%
  split(f = d$census_tract_vintage)

message('loading census tract shapefiles...')
all_tracts <- readRDS('/app/census_tracts_1970_to_2020.rds')

tracts_to_join <- all_tracts[names(all_tracts) == names(d)]

message('joining to census tracts...')
d <- purrr::map2(d, tracts_to_join, st_join) %>% 
  bind_rows() %>% 
  st_drop_geometry()

## merge back on .row after unnesting .rows into .row
dht::write_geomarker_file(d = d,
                          raw_data = raw_data %>% select(-start_date, -end_date),
                          filename = opt$filename,
                          geomarker_name = 'st_census_tract',
                          version = '0.0.3')
