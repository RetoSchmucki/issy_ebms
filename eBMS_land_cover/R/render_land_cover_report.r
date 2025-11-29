library(rmarkdown)

source("R/extract_clc_transects.r")

## Read in transect coordinates
# transects <- read_csv("data/whole_ebms_extract_2020_2024_for_ukceh_land_cover_analysis_extracted_on_20251121/ebms_transect_coord.csv")

## Read in eBMS transect coordinates
transects <- read_csv("data/whole_ebms_extract_2020_2024_for_ukceh_land_cover_analysis_extracted_on_20251121/ebms_transect_coord.csv")


## Knit R markdown report
rmarkdown::render("R/land_cover_report.rmd")  #,
                #   params = list(transects = transects))
