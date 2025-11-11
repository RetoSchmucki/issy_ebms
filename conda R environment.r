mkdir ~/miniforge3_src
cd ~/miniforge3_src

# get miniforge installer
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
bash Miniforge3-$(uname)-$(uname -m).sh

### clean up
rm -r ~/miniforge3_src

## initalize conda for bash shell
conda init

## restart shell or run
source ~/.bashrc

## update conda to latest version
conda update -n base -c conda-forge conda

## create new conda environment, named R 4.5
conda create --name R4.5

## activate the R 4.5 environment
conda activate R4.5

## ADD NECESSARY DEPENDENCY FOR GIS PACKAGES
conda install -c conda-forge proj gdal udunits2 pkgconfig

## INSTALL latest R in R4.5 env
conda install -c conda-forge r-base r-essentials r-devtools

## INSTALL R packages needed for data handling
conda install -c conda-forge r-data.table r-dplyr r-readr r-tidyr r-stringr r-lubridate r-purrr r-openxlsx r-glue r-logr

## Install R packages needed for db connection
conda install -c conda-forge r-rpostgres r-dbi

## Install pandoc and R packages needed for report generation
conda install -c conda-forge pandoc r-rmarkdown r-knitr r-bookdown r-plotly r-tinytex

## Install R packages needed for spatial data handling and mapping
conda install -c conda-forge r-sf r-terra r-stars r-lwgeom

## Install R packages needed for r language help 
conda install -c conda-forge r-languageserver

## Install rbms package from GitHub
R
devtools::install_github("RetoSchmucki/rbms")
install.packages("viridis")
install.packages("gridExtra")
install.packages("rnaturalearth")
q()
