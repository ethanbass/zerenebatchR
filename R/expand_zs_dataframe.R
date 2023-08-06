#' Expand data.frame
#'
#' This function facilitates stacking photos that are numbered sequentially. It
#' must be supplied with a \code{data.frame} with columns containing the
#' @param df A data.frame containing the first and last photo, file path, and
#' grouping variable.
#' @param c_path String or numerical index specifying the column where the file
#' paths can be found. Paths should
#' @param c_id String or numerical index specifying column where factor can
#' be found for grouping images.
#' @param c_start String or numerical index specifying the column containing
#' the first photo of each stack.
#' @param c_end String or numerical index specifying the column containing
#' the last photo of each stack.
#' @param extension String specifying the file extension of the images. The
#' extension must be in the correct case so it matches exactly to the extension
#' of the files to be stacked.
#' @return Expanded data.frame
#' @export

expand_zs_dataframe <- function(df, c_path, c_id, c_start, c_end,
                                extension = "JPG"){
  # check missing lines
  rm <- which(is.na(df[,c_start]) | is.na(df[,c_end]))
  if (length(rm) > 0){
    df <- df[-rm,]
  }
  # check for photos out of order
  wrong_order <- which(!(df[,c_start] < df[,c_end]))
  if (length(wrong_order) > 0){
    stop(paste0("Images appear to be out of order. Double check line ",
                sQuote(paste0(wrong_order,collapse=", ")), "."))
  }
  extension <- gsub("^\\." ,"", extension)
  pp <- lapply(1:nrow(df), function(i){
    data.frame(id = paste(df[i, c_id], collapse="_"),
               path = paste0(df[i,c_path],
                             seq(df[i, c_start], df[i, c_end], by = 1),
                                                                    ".", extension))
  })
  pp <- do.call(rbind, pp)
  # check for missing files
  missing_files <- which(!file.exists(pp$path))
  if (length(missing_files > 0)){
    warning(paste0("Some image files could not be found: ",
                   (paste0(sQuote(missing_files), collapse=", ")), "."))
    pp <- pp[-missing_files,]
  }
  pp
}
