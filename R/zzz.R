.onLoad <- function(libname, pkgname){
  try(env <- reticulate::configure_environment("zerenebatchR"))

  img_sim <- try(reticulate::import_from_path("image_similarity",
                                                       path = system.file("python", package = "zerenebatchR"),
                                                       delay_load = TRUE), silent = TRUE)

  circular_crop <- try(reticulate::import_from_path("circular_crop",
                                                    path = system.file("python", package = "zerenebatchR"),
                                                    delay_load = TRUE), silent = TRUE)

  try(image_similarity <<- img_sim[["image_similarity"]],silent=TRUE)


  try(crop_images <<- circular_crop[["crop_images"]])
}


