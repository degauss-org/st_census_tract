FROM rocker/r-ver:4.0.4

# install required version of renv
RUN R --quiet -e "install.packages('remotes', repos = 'https://cran.rstudio.com')"
# make sure version matches what is used in the project: packageVersion('renv')
ENV RENV_VERSION 0.14.0
RUN R --quiet -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

WORKDIR /app

RUN apt-get update \
  && apt-get install -yqq --no-install-recommends \
  libgdal-dev \
  libgeos-dev \
  libudunits2-dev \
  libproj-dev \
  libv8-dev \
  && apt-get clean

COPY renv.lock .
RUN R --quiet -e "renv::restore(repos = c(CRAN = 'https://packagemanager.rstudio.com/all/__linux__/focal/latest'))"

ADD https://geomarker.s3.us-east-2.amazonaws.com/geometries/census_tracts_1970_to_2020.rds census_tracts_1970_to_2020.rds
COPY entrypoint.R .

WORKDIR /tmp

ENTRYPOINT ["/app/entrypoint.R"]
