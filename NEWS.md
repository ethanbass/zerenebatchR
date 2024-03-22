# zerenebatchR 0.2.3

* Allow unmodified digits in `expand_zs_dataframe` by setting `digits = NULL`.
* Stop with error if `path_out` isn't specified in `run_zs_batch`.

# zerenebatchR 0.2.2

* Allow multiple columns as inputs to `c_id` in `run_zs_batch`.
* Automatically expand `path_out`, so abbreviated paths don't cause Zerene Stacker to error out.
* Added `digits` argument to add leading zeros to file numbers in `expand_zs_dataframe`.

# zerenebatchR 0.2.1

* Added check for duplicated ids in `expand_zs_dataframe`.

# zerenebatchR 0.2.0

* Added option to create export directory if it doesn't exist.
* Added `expand_zs_dataframe` function to expand data.frame specifying the first 
and last photos in a sequence.

# zerenebatchR 0.1.0

* Added a `NEWS.md` file to track changes to the package.
