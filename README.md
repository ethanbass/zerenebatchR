# zerenebatchR

<!-- badges: start -->
  [![zerenebatchR status badge](https://ethanbass.r-universe.dev/badges/zerenebatchR)](https://ethanbass.r-universe.dev)
  [![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/emersion/stability-badges#experimental)
<!-- badges: end -->

## Overview

zerenebatchR is an R utility for batch processing images in [Zerene Stacker](http://www.zerenesystems.com/cms/stacker). Batch processing in Zerene Stacker requires you to already have the images you want to stack organized into folders by stack. If you have many stacks, this can be onerous. zerenebatchR is intended to facilitate easier batch processing of images using R. (zerenebatchR is not endorsed by the developers of Zerene Stacker).


## Installation

zerenebatchR can be installed from GitHub as follows:

```
install.packages("remote")
remotes::install_github("https://github.com/ethanbass/zerenebatchR/")
```

Or install directly from my R Universe repo:

```
install.packages("zerenebatchR", repos="https://ethanbass.r-universe.dev/", type="source")
```

## System requirements

zerenebatchR has not yet been tested on Windows and may very well not work without modification due to file path issues.

## Usage

The package contains only one function (`run_zs_batch`) which can be used to create and run batch scripts in Zerene Stacker. zerenebatchR can also create the folders of image stacks required by Zerene Stacker. Please see the documentation for further details, by running `?zerenebatchR::run_zs_batch` from your R console.
