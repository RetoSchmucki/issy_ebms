## Load libraries
library(countrycode)
library(rmarkdown)


### Set parameters =========================================================================================================================

## Specify country/area name and scheme ID
country <- "Spain"
scheme_id <- c("ESBMS", "ES-BABMS", "ES-ZEBMS", "ES-CTBMS")
country_iso_a3 <- countrycode(country, origin = "country.name.en", destination = "iso3c")

## Specify years to include
# A single year or multiple years, must be between 2020-2024
years <- c('2020', '2021', '2022', '2023', '2024')

## Choose whether to overwrite pre-processed data files if they already exist e.g. raster cropped to the country of interest
# Only set to TRUE if there are updates needed in the pre-processing steps, as these take some time to run
# This doesn't affect whether the R markdown output is overwritten
overwrite_files <- FALSE

### Set file paths =========================================================================================================================

## Path: Temp files folder for terra
tmp_dir <- "terra_tmp"

## URL: Raster of Corine Land Cover values
# note that we add the prefix "/vsicurl/" to the COG URL found in https://stac.ecodatacube.eu/
cog_url <- "/vsicurl/https://s3.ecodatacube.eu/arco/landcover_clc.plus_f_30m_0..0cm_20220101_20241231_eu_epsg.3035_v20250327.tif"

## Path: Transect coordinates
transects_path <- "data/whole_ebms_extract_2020_2024_for_ukceh_land_cover_analysis_extracted_on_20251121/ebms_transect_coord.csv"

## Path: Visits
visits_path <- "data/whole_ebms_extract_2020_2024_for_ukceh_land_cover_analysis_extracted_on_20251121/ebms_visit.csv"

## Path: CLC values for eBMS transects, extracted from CLC raster
ebms_clc_path <- "data/eBMS_land_cover/ebms_transect_clc.csv"

country_raster_path <- paste0("data/eBMS_land_cover/", country_iso_a3, "_raster.tif")

## Path: Frequency table of CLC values for the selected country
country_clc_freq_path <- paste0("data/eBMS_land_cover/", country_iso_a3, "_clc_freq.csv")

## Path: R markdown html output
if (length(scheme_id) == 1) {
    output_file_path = paste0("../output/", country, "_", scheme_id, "_land_cover_report.html")
} else if (length(scheme_id) > 1) {
    output_file_path = paste0("../output/", country, "_multi_scheme_land_cover_report.html")
}

## Run data processing script ==============================================================================================================
source("R/extract_clc_transects.r")

## Knit R markdown report ==================================================================================================================
rmarkdown::render("R/land_cover_report.rmd",
                  params = list(transects = transects,
                                country = country,
                                scheme_id = scheme_id,
                                country_iso_a3 = country_iso_a3),
                  output_file = output_file_path)
