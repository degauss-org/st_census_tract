.PHONY: build test shell clean

build:
	docker build -t st_census_tract .

test:
	docker run --rm -v "${PWD}/test":/tmp st_census_tract my_address_file_geocoded.csv

shell:
	docker run --rm -it --entrypoint=/bin/bash -v "${PWD}/test":/tmp st_census_tract

clean:
	docker system prune -f