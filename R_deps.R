
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/latest/bin/linux/trixie-x86_64/4.5"))
# BiocManager builds its repo URLs from BioC_mirror, not from options("repos"), so it
# ignores the CRAN line above unless this is also set — without it, Bioconductor
# packages come from bioconductor.org (source-only on Linux) instead of PPM binaries.
options(BioC_mirror = "https://packagemanager.posit.co/bioconductor/latest")

install.packages(c(
  "qtl", "gplots", "ltm", "RColorBrewer", "rrBLUP", "plyr", "rjson", "agricolae",
  "gtools", "gdata", "bitops", "caTools", "KernSmooth", "msm", "mvtnorm", "polycor",
  "sfsmisc", "nlme", "irlba", "lme4", "randomForest", "data.table", "ggplot2",
  "devtools", "lsmeans", "dplyr", "caret", "withr", "fpc", "ggfortify", "cluster",
  "rlang", "BGLR", "sommer", "waves", "ggthemes", "GGally", "gridExtra", "stringr",
  "AGHmatrix", "ape", "blocksdesign", "bookdown", "catchr", "DT", "effects", "emmeans",
  "EnvStats", "factoextra", "FielDHub", "gmailr", "gstat", "httr", "jsonlite", "knitr",
  "leaflet", "lmerTest", "lubridate", "magrittr", "mice", "moments", "na.tools", "ona",
  "plotly", "R2D3", "raster", "RCurl", "readr", "reshape2", "rstatix", "shiny",
  "shinyjs", "shinythemes", "SpATS", "spdep", "stability", "stringi", "tibble",
  "tidyr", "tidyverse", "xfun"
))

if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager"); BiocManager::install(c("SNPRelate", "affy", "VariantAnnotation", "ggtree", "treeio"))

if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
remotes::install_github(c("solgenomics/rPackages/phenoAnalysis",  "solgenomics/rPackages/genoDataFilter", "reyzaguirre/st4gi"))
