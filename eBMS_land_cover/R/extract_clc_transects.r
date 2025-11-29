### Author: Reto Schmucki
### Date: 31/10/2025
### NOTE: on the VM, use RStudio to install the spatial packages (sf, terra, geodata)
### ============================

### COG resource: https://s3.ecodatacube.eu/arco/landcover_clc.plus_f_30m_0..0cm_20220101_20241231_eu_epsg.3035_v20250327.tif
# R

library(terra)
library(sf)
library(geodata)
library(raster)
library(tidyverse)
library(countrycode)

### Set parameters =========================================================================================================================

## Specify country/area name and scheme ID
country <- "France"
scheme_id <- "FRBMS"
country_iso_a3 <- countrycode(country, origin = "country.name.en", destination = "iso3c")

## Choose whether to overwrite pre-processed files if they already exist e.g. raster cropped to the country of interest
# Only set to TRUE if there are updates needed in the pre-processing steps, as these take some time to run
overwrite_files <- TRUE

### Set file paths =========================================================================================================================

## Path: Temp files folder for terra
tmp_dir <- "/home/isorus/tmp"

## URL: Raster of Corine Land Cover values
# note that we add the prefix "/vsicurl/" to the COG URL found in https://stac.ecodatacube.eu/
cog_url <- "/vsicurl/https://s3.ecodatacube.eu/arco/landcover_clc.plus_f_30m_0..0cm_20220101_20241231_eu_epsg.3035_v20250327.tif"

## Path: Transect coordinates
transects_path <- "data/whole_ebms_extract_2020_2024_for_ukceh_land_cover_analysis_extracted_on_20251121/ebms_transect_coord.csv"

## Path: CLC values for eBMS transects, extracted from CLC raster
ebms_clc_path <- "data/whole_ebms_extract_2020_2024_for_ukceh_land_cover_analysis_extracted_on_20251121/ebms_transect_clc.csv"

country_raster_path <- paste0("data/eBMS_land_cover/", scheme_id, "_area_raster.tif")

## Path: Frequency table of CLC values for the selected country
country_clc_freq_path <- paste0("data/eBMS_land_cover/", country, "_clc_freq.csv")

### Prep data ==============================================================================================================================

## Set temp dir to shared drive to avoid memory issues
dir.create(tmp_dir, showWarnings = FALSE)
terraOptions(tempdir = tmp_dir)

## Read in eBMS transect coordinates
transects <- read_csv(transects_path)

transect_coords <- transects %>% 
    dplyr::select(longitude = section_lon, latitude = section_lat)

## Set labels for CLC values
clc_labels <- data.frame(
  clc = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 253, 254, 255),
  clc_lab = c("Sealed",
              "Woody needle leaved trees",
              "Woody broadleaved deciduous trees",
              "Woody broadleaved evergreen trees",
              "Low-growing woody plants",
              "Permanent herbaceous",
              "Periodically herbaceous",
              "Lichens and mosses",
              "Non and sparsely vegetated",
              "Water",
              "Snow and ice",
              "Coastal seawater buffer",
              "Outside area",
              "No data")
)

## Read in Corine Land Cover raster
clc_r <- terra::rast(cog_url)

### Get Corine Land Cover for eBMS transects ================================================================================================

## Extract the CLC for each transect
# If the resulting csv file already exists and we don't want to overwrite files, read it in
# Otherwise run the extraction and save the output to csv
if (file.exists(ebms_clc_path) & !overwrite_files) {
  ebms_clc <- read_csv(ebms_clc_path)
} else {
  ebms_clc <- terra::extract(clc_r, transect_coords)
  colnames(ebms_clc) <- c("ID", "clc")

  write_csv(ebms_clc, ebms_clc_path)
}

## Check extracted values are the same length as original dataframe
# (For the next step, rows are expected to be in the same order as transects df)
if (nrow(transects) != nrow(ebms_clc)) {
  stop(paste("terra::extract extracted", nrow(ebms_clc)," CLC values for", nrow(transects), "transects. The subsequent code expects 1 CLC value per transect."))
}

## Add CLC to original transects data
transects$clc <- ebms_clc$clc

# Add CLC text labels
transects <- transects %>%
  left_join(clc_labels, by = "clc")

### CLC data checks for eBMS transect locations ===============================================================================================

## Check count of each CLC class for transects
# transects %>% 
#   group_by(clc, clc_lab) %>%
#   summarise(n = n())

## Check which schemes have NA CLC values
# Just a few each in UK, Slovenia and Denmark

# transects %>%
#   filter(is.na(clc)) %>%
#   group_by(bms_id) %>%
#   summarise(na_values = n())

## UKBMS transects mostly have a CLC of 0
# Some have actual classes - all in NI or on the coast

# transects %>%
#   filter(bms_id == "FRBMS") %>%
#   dplyr::select(bms_id, clc) %>%
#   group_by(clc) %>%
#   summarise(n = n())

## Check which schemes have 0 CLC values
# The only other transects with a CLC of 0 are a few in Ireland
# But they're actually in England/Wales

# transects %>%
#   filter(clc == 0) %>%
#   group_by(bms_id) %>%
#   summarise(n = n())

## Check locations of a given CLC class
# clc_inspect <- transects %>%
#   filter(clc != 0 & bms_id == "UKBMS")

# europe_map <- rnaturalearth::ne_countries(continent = "Europe") %>%
#   st_transform(crs = crs(clc_r))

# plot(europe_map$geometry)
# points(clc_inspect$transect_lon, clc_inspect$transect_lat, col = "red", cex = 0.3)

### Get CLC split for selected scheme's transects =============================================================================================

## Filter transects to relevant scheme
transects_scheme <- transects %>%
  filter(bms_id == scheme_id)

## Calculate split of CLC classes
summary_transects <- transects_scheme %>%
  group_by(clc, clc_lab) %>%
  summarise(n_cell = n(),
            perc = n() / nrow(transects_scheme) * 100,
            perc_weighted = sum(section_length, na.rm = TRUE)/sum(transects_scheme$section_length, na.rm = TRUE) * 100
            )

### Get CLC split for whole scheme area =======================================================================================================

# If country raster is already saved and we don't want to overwrite files, then read it in
# Otherwise go through pre-processing to produce country raster, and save it to file

if (file.exists(country_raster_path) & !overwrite_files) {
  country_clc <- terra::rast(country_raster_path)
} else {
  
  ## Get boundaries for selected country
# Use geounit instead of country to exclude overseas territories e.g. French Guiana for France
country_vec <- rnaturalearth::ne_countries(geounit = "France", type = "map_units", scale = "medium", returnclass = "sf") %>%
  filter(iso_a3 == country_iso_a3) %>%
  st_transform(crs = crs(clc_r))

  ## Preview geometry of country_vec
  # plot(country_vec$geometry)

  ## Crop CLC raster to country boundaries
  country_clc <- terra::crop(clc_r, country_vec, mask = TRUE)

  ## Set non-valid values to NA
  na_values <- c(0, 253, 254, 255)
  country_clc[country_clc %in% na_values] <- NA

  ## Remove NA cells
  # This only works on cells at the edge of the raster
  country_clc <- trim(country_clc, value = 254)

  ## Check country_clc has been cropped correctly to extent of country_vec
  # plot(ext(country_clc))
  # lines(country_vec)

  ## Preview cropped clc raster
  # terra::plot(country_clc, type = "classes")

  ## Save raster
  raster::writeRaster(country_clc, country_raster_path,
                      format = "GTiff", overwrite = TRUE)

}










## Read processed raster from file
# country_clc <- terra::rast(country_raster_path)

## Get frequency count of cells in each class
# Saved as csv as this line takes some time to run

# country_clc_freq <- freq(country_clc)
# write_csv(country_clc_freq, "data/whole_ebms_extract_2020_2024_for_ukceh_land_cover_analysis_extracted_on_20251121/fr_scheme_area_clc.csv")

# Read in CLC frequency table
country_clc_freq <- read_csv(country_clc_freq_path)

# Summarise CLC classes for whole scheme area
summary_country <- country_clc_freq %>%
  dplyr::select(clc = value,
         n_cell = count) %>%
  mutate(perc = n_cell / sum(n_cell) * 100)

########################## NEXT STEPS ##########################

# |/| Try using trim function to remove NAs and NA-like values like 0, 253, 254
# |/| Get proportion of transects in France that are in each CLC class
# | | Get list of country names for BMS schemes
# | | Make this into a function I can run on each country
# |/| Try to extract CLC values for entire country (may struggle...) and write to csv
# |/| Add step to save cropped-to-country raster file so it doesn't need to be recreated each time


