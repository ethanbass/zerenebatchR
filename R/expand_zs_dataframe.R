#' Expand data.frame
#'
#' This function facilitates stacking photos that are numbered sequentially. It
#' must be supplied with a \code{data.frame} with columns containing the
#' information about the images to be stacked.
#' @importFrom stringr str_pad
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
#' @param digits How many digits should be in the number.
#' @return Expanded data.frame
#' @export

expand_zs_dataframe <- function(df, c_path, c_id, c_start, c_end,
                                extension = "JPG", digits = 4){
  # check missing lines
  df <- as.data.frame(df)
  df[,c_start] <- as.numeric(df[,c_start])
  df[,c_end] <- as.numeric(df[,c_end])
  rm <- which(is.na(df[, c_start]) | is.na(df[, c_end]))
  if (length(rm) > 0){
    df <- df[-rm,]
  }
  if (length(c_id) > 1){
    df$id <- apply(df[, c_id], MARGIN = 1, function(x) paste(x, collapse = "-"))
  } else{
    df$id <- df[, c_id]
  }
  # check for duplicated IDs
  duplicated_ids <- duplicated(df$id)
  if (any(duplicated_ids)){
    stop(paste0("Some identifiers appear to be duplicated. Please double check IDs and try again.
         Duplicated IDs: ", paste(sQuote(df[which(duplicated_ids), "id"]), collapse = ", "), "."))
  }
  # check for photos out of order
  wrong_order <- which(!(df[, c_start] < df[, c_end]))
  if (length(wrong_order) > 0){
    stop(paste0("Images appear to be out of order. Double check IDs: ",
                paste(sQuote(df[wrong_order,"id"]), collapse = ", "), "."))
  }
  extension <- gsub("^\\." ,"", extension)
  pp <- lapply(1:nrow(df), function(i){
    data.frame(id = paste(df[i, "id"], collapse = "_"),
               path = paste0(df[i, c_path],
                             stringr::str_pad(seq(df[i, c_start], df[i, c_end], by = 1),
                                              width = digits, side = "left", pad = "0"),
                                                                    ".", extension))
  })
  pp <- do.call(rbind, pp)
  # check for missing files
  missing_files <- pp[which(!file.exists(pp$path)), "path"]
  if (length(missing_files) > 0){
    if (length(missing_files) == nrow(df)){
      stop("Files could not be found. Please check path(s) and try again.")
    } else{
      warning(paste0("Some image files could not be found: ",
                     (paste0(sQuote(missing_files), collapse=", ")), "."))
      pp <- pp[-missing_files,]
    }
  }
  pp
}
