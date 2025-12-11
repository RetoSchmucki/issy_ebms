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

### Prep data ==============================================================================================================================

## Set temp dir to shared drive to avoid memory issues
dir.create(tmp_dir, showWarnings = FALSE)
terraOptions(tempdir = tmp_dir)

## Get list of transects visited during selected years
visits <- read_csv(visits_path) %>%
  filter(year %in% years)

transects_list <- unique(visits$transect_id)

## Read in eBMS transect coordinates and filter to transects visited in relevant year(s)
transects <- read_csv(transects_path) %>%
    filter(transect_id %in% transects_list)

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
# Otherwise run the extraction and save the output to csv (~10 mins runtime)
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

### Calculate CLC split for selected scheme's transects =======================================================================================

## Filter transects to relevant scheme and filter out NA locations
transects_scheme <- transects %>%
  filter(bms_id %in% scheme_id,
         !is.na(transect_lon),
         !is.na(transect_lat))

## Calculate split of CLC classes
summary_transects <- transects_scheme %>%
  group_by(clc, clc_lab) %>%
  summarise(n_cell = n(),
            perc = n() / nrow(transects_scheme) * 100,
            perc_weighted = sum(section_length, na.rm = TRUE)/sum(transects_scheme$section_length, na.rm = TRUE) * 100
            )

### Get CLC split for whole country/scheme area ===============================================================================================

## If country raster is already saved and we don't want to overwrite files, then read it in
## Otherwise go through pre-processing to produce country raster, and save it to file
if (file.exists(country_raster_path) & !overwrite_files) {
  country_clc <- terra::rast(country_raster_path)
} else {
  ## Get boundaries for selected country
  # Use geounit instead of country to exclude overseas territories e.g. French Guiana for France
country_vec <- rnaturalearth::ne_countries(geounit = country, type = "map_units", scale = "medium", returnclass = "sf") %>%
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
  country_clc <- trim(country_clc)

  ## Check country_clc has been cropped correctly to extent of country_vec
  # plot(ext(country_clc))
  # lines(country_vec)

  ## Preview cropped clc raster
  # terra::plot(country_clc, type = "classes")

  ## Save raster
  raster::writeRaster(country_clc, country_raster_path,
                      overwrite = TRUE)

}


## If CLC count is already saved and we don't want to overwrite files, then read it in
## Otherwise make a frequency table of cells in each CLC class
if (file.exists(country_clc_freq_path) & !overwrite_files) {
  ## Read in frequency table
  country_clc_freq <- read_csv(country_clc_freq_path)
} else {
  ## Calculate frequency table
  country_clc_freq <- freq(country_clc)

  ## Save frequency table
  write_csv(country_clc_freq, country_clc_freq_path)
}

## Summarise CLC classes for whole scheme area
summary_country <- country_clc_freq %>%
  dplyr::select(clc = value,
         n_cell = count) %>%
  mutate(perc = n_cell / sum(n_cell) * 100)

