FROM rocker/r-ver:4.0.5

# DeGAUSS container metadata
ENV degauss_name="st_census_tract"
ENV degauss_version="0.2.0"
ENV degauss_description="census tract identifiers with appropriate vintage"
# ENV degauss_argument="short description of optional argument [default: 'insert_default_value_here']"

# add OCI labels based on environment variables too
LABEL "org.degauss.name"="${degauss_name}"
LABEL "org.degauss.version"="${degauss_version}"
LABEL "org.degauss.description"="${degauss_description}"
LABEL "org.degauss.argument"="${degauss_argument}"

RUN R --quiet -e "install.packages('remotes', repos = c(CRAN = 'https://packagemanager.rstudio.com/all/__linux__/focal/latest'))"

RUN R --quiet -e "remotes::install_github('rstudio/renv@0.15.3')"

WORKDIR /app

RUN apt-get update \
    && apt-get install -yqq --no-install-recommends \
    libgdal-dev \
    libgeos-dev \
    libudunits2-dev \
    libproj-dev \
    && apt-get clean

COPY renv.lock .

RUN R --quiet -e "renv::restore(repos = c(CRAN = 'https://packagemanager.rstudio.com/all/__linux__/focal/latest'))"

ADD https://geomarker.s3.us-east-2.amazonaws.com/geometries/census_tracts_1970_to_2020_valid.rds census_tracts_1970_to_2020_valid.rds
COPY entrypoint.R .

WORKDIR /tmp

ENTRYPOINT ["/app/entrypoint.R"]
