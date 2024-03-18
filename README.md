# zerenebatchR

<!-- badges: start -->
  [![zerenebatchR status badge](https://ethanbass.r-universe.dev/badges/zerenebatchR)](https://ethanbass.r-universe.dev)
  [![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/emersion/stability-badges#experimental)
<!-- badges: end -->

## Overview

`zerenebatchR` is an R utility for batch processing images in [Zerene Stacker](http://www.zerenesystems.com/cms/stacker). [Batch processing in Zerene Stacker](https://zerenesystems.com/cms/stacker/docs/howtouseit#batch_processing) requires you to already have the images you want to process organized into folders by stack. If you have many stacks, this can be an onerous task. `zerenebatchR` aims to simplify this process by automatically grouping images into folders using information supplied from a spreadsheet and creating the required batch file. **`zerenebatchR` is not created or endorsed by the developers of Zerene Stacker.**


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

## Usage

The function `expand_zs_batch` can be used to expand a `data.frame` containing the first and last file in a stack. This expanded `data.frame` can then be fed to the `run_zs_batch` function to stack images in Zerene Stacker. `zerenebatchR` automatically creates the folders of images that are required for batch image processing in Zerene Stacker and creates the batch script. For further details, please see the documentation by running `?zerenebatchR::run_zs_batch` or `?zerenebatchR::expand_zs_batch` from your R console.
