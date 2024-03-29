#!/usr/local/bin/Rscript

dht::greeting()

## load libraries without messages or warnings
withr::with_message_sink("/dev/null", library(dplyr))
withr::with_message_sink("/dev/null", library(tidyr))
withr::with_message_sink("/dev/null", library(sf))

doc <- "
      Usage:
      entrypoint.R <filename>
      "

opt <- docopt::docopt(doc)

## for interactive testing
## opt <- docopt::docopt(doc, args = 'test/my_address_file_geocoded.csv')

message("reading input file...")
raw_data <- dht::read_lat_lon_csv(opt$filename)

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

## add code here to calculate geomarkers

message('determining census decade for each date range...')
d <- d %>%
  mutate(min_year = glue::glue('{floor(lubridate::year(start_date) / 10)}0'),
         max_year = glue::glue('{floor(lubridate::year(end_date) / 10)}0')) %>%
  group_by(.row) %>%
  nest() %>%
  mutate(year_seq = purrr::map(data, ~seq(.x$min_year, .x$max_year, 10))) %>%
  unnest(cols = c(data, year_seq)) %>%
  mutate(day1 = as.Date(glue::glue('{year_seq}-01-01')),
         dayx = as.Date(glue::glue('{year_seq + 9}-12-31')),
         new_start_date = if_else(start_date > day1, start_date, day1),
         new_end_date = if_else(end_date < dayx, end_date, dayx),
         census_tract_vintage = glue::glue('{floor(lubridate::year(new_start_date) / 10)}0'))

cli::cli_alert_warning('{length(unique(d$.row[d$min_year != d$max_year]))} date range{?s} span{?s/} more than one census decade and will be split to one row per decade.')

d <- d %>%
  select(.row, lat, lon,
         start_date = new_start_date,
         end_date = new_end_date,
         census_tract_vintage) %>%
  group_by(lat, lon) %>%
  nest(.rows = c(.row)) %>%
  st_as_sf(coords = c('lon', 'lat'), crs = 4326) %>%
  st_transform(5072)

d <- d %>%
  split(f = d$census_tract_vintage)

message('loading census tract shapefiles...')
all_tracts <- readRDS('/app/census_tracts_1970_to_2020_valid.rds')

tracts_to_join <- all_tracts[names(all_tracts) %in% names(d)]

message('joining to census tracts...')
d <- purrr::map2(d, tracts_to_join, ~suppressWarnings(st_join(.x, .y, largest = TRUE))) %>%
  bind_rows() %>%
  sf::st_drop_geometry()

## merge back on .row after unnesting .rows into .row
dht::write_geomarker_file(d = d,
                          raw_data = raw_data %>% select(-start_date, -end_date),
                          filename = opt$filename)
