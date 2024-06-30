#' Image similarity
#' Calculates structural similarity score for consecutive images in the provided
#' directory.
#' @name image_similarity
#' @param path_in Path with directory containing image files.
#' @param path_out Path to write the similarities
#' @param ext File extension. Defaults to "jpg".
#' @export
image_similarity <- NULL

#' Crop images
#' Detects field of view using Hough Circle Transform and crops images at the
#' edge.
#' @name crop_images
#' @param path Path with directory containing image files.
#' @param path_out Path to write cropped image files.
#' @param radius Vector with minimum and maximum radius of edge in pixels.
#' Defaults to \code{c(2200,2400)}.
#' @param crop_factor Multiplier for crop radius. Defaults to \code{0.9}.
#' @export
crop_images <- NULL
