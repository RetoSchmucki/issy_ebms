## Extract land cover for eBMS monitoring sites (transect)

1. Access Corine Land Cover (CLC) product from Copernicus to extract and inform the land cover and habitat type that are covered by the BMS transects contained in the eBMS database. If possible, we should use the latest [CLCplus-backbone](https://land.copernicus.eu/en/products/clc-backbone).

2. IF possible, we would avoid having to download the CLC data and use a Cloud Optimized GeoTIFF (COG) and extract value from the cloud. I never use this data cube, but I think that this [ecodatacube](https://stac.ecodatacube.eu/landcover_clc.plus/collection.json?.language=en).

3. To extract from GeoTIFF (local raster or COG), the script could use the function available in the terra packages. 

4. After extractions, we could analyse the proportion of each habitat (Land Cover) type that is covered by the BMS transects. These metric could be compared to the proportion of each habitat per contry and the EU.

5. To extract the data at the country level, we can do the extraction with the country polygon.

### Note
Corine Land Cover can be visualise in QGIS using the WMS provided by Copernicus ()