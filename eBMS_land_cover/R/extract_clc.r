### Author: Reto Schmucki
### Date: 31/10/2025
### NOTE: on the VM, use RStudio to install the spatial packages (sf, terra, geodata)
### ============================

### COG resource: https://s3.ecodatacube.eu/arco/landcover_clc.plus_f_30m_0..0cm_20220101_20241231_eu_epsg.3035_v20250327.tif
R

library(terra)
library(sf)
library(geodata)

# setGDALconfig("AWS_NO_SIGN_REQUEST", "YES")
# setGDALconfig("GDAL_DISABLE_READDIR_ON_OPEN", "EMPTY_DIR")

## generate random points in France

set.seed(42876) 
fr_border = sf::st_as_sf(geodata::gadm("GADM", country = "FRA", level = 0))
sf_point = sf::st_sf(sf::st_sample(x = fr_border, size = 25, type = "random"))

## extract clc value for the points
## note that we add the prefix "/vsicurl/" to the COG URL found in https://stac.ecodatacube.eu/
cog_url <- "/vsicurl/https://s3.ecodatacube.eu/arco/landcover_clc.plus_f_30m_0..0cm_20220101_20241231_eu_epsg.3035_v20250327.tif"
clc_r <- terra::rast(cog_url)

## extract the CLC for each points
extr_val <- terra::extract(clc_r, terra::vect(sf::st_transform(sf_point, 3035)))

## extract/crop the extent (bbox of the points)
bbox_r <- terra::crop(clc_r, terra::vect(sf::st_buffer(sf::st_transform(sf_point, 3035)[1,], 5000)))
raster::writeRaster(bbox_r, "my_raster.TIFF", datatype="INT1U", overwrite=TRUE)

