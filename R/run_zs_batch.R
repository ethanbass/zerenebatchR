globalVariables(c("."))

#' Create and run batch scripts in Zerene Stacker
#' @import xml2
#' @import magrittr
#' @importFrom fs dir_delete path_home dir_exists path
#' @param files A data.frame or character vector. If \code{stack == TRUE},
#' a \code{data.frame} should be provided with at least 2 columns containing the paths of
#' the files to parse (\code{c_path}) and a grouping factor (\code{c_split}). If
#' \code{stack == FALSE}, a character vector should be provided containing paths
#' to the stacked files.
#' @param c_path String or numerical index specifying column where paths can be found.
#' @param c_split String or numerical index specifying column where factor can
#' be found for grouping images.
#' @param path_out directory to export converted files.
#' @param stacker Which stacking algorithm to use. Either \code{pmax} or \code{dmap}.
#' @param temp Logical. If TRUE, the function will stack files into a temp
#' directory which will be deleted when the operation is completed. Thus,
#' the organization of the original image files will be maintained. Otherwise,
#' images will be moved permanently into new folders according to the provided
#' grouping variable. Defaults to TRUE.
#' @param path_template Path to custom template to be customized according to
#' the provided arguments (optional).
#' @param path_xml path to write xml file (optional).
#' @param stack Logical. Whether to stack the files or not. Defaults to TRUE.
#' @return No return value.
#' @section Side effects: Images will be stacked according to the provided grouping
#' variable, a Zerene Stacker batch file will be generated, and images will be stacked
#' into the folder specified by \code{path_out}.
#' @author Ethan Bass
#' @export

run_zs_batch <- function(files, c_split = 1, c_path = 2,
                               path_out, stacker = c("pmax", "dmap"),
                               temp, path_template = NULL,
                               path_xml = NULL, stack = TRUE){
  if (missing(path_out)){
    stop("Please specify a path to export the stacked images to `path_out`.")
  }
  if (stack){
    if (!inherits(files, "data.frame")){
      stop("If `stack == TRUE`, a `data.frame` should be provided to the `files` argument.")
    }
    if (!stack){
      stop("If `stack == FALSE`, a character vector of stacked files should be provided to the `files` argument.")
    }
    if (nrow(files) == 0){
      stop("Files not found.")
    }
  } else{
    if (!inherits(files, "character")){
      stop("If `stack == FALSE`, please supply a character vector to the `files` argument containing the paths to stacked images.")
    }
    if (stack){
      stop("If `stack == TRUE`, a `data.frame` should be provided to the files argument.")
    }
    exists <- fs::dir_exists(files)
    if (!any(exists)){
      stop("The provided directories do not exist. Please check paths and try again.")
    }
    if (!all(exists)){
      warning(paste("Some of the provided directories do not exist: ",
                    paste(files[which(!exists)], collapse="\n \t"),
                    sep = "\n \t"))
    }
  }

  if (missing(temp)){
    if (missing(path_out)){
      temp <- TRUE
    } else{ temp <- FALSE}
  }

  if (!missing(path_out)){
    dir_exists <- dir.exists(path_out)
    if (!dir_exists){
      ans <- readline("Export directory not found. Create directory (y/n)?")
      if (ans %in% c("y","Y","yes","Yes","YES")){
        dir.create(path_out)
      }
    }
  }

  stacker <- match.arg(stacker, c("pmax", "dmap"))

  # get launch command

  system <- .Platform$OS.type

  launch_cmd_path <- switch(system,
                            "unix" = fs::path_home("Library/Preferences/ZereneStacker/zerenstk.launchcmd"),
                            "windows" = fs::path_home("AppData\\ZereneStacker\\zerenstk.launchcmd"),
                            "linux" = "~/.ZereneStacker/zerenstk.launchcmd"
  )

  launch_cmd <- readLines(launch_cmd_path)

  # stack files in temporary folders
  if (stack){
    stacks <- stack_files(df = files, c_path = c_path, c_split = c_split, temp = temp)
  } else{
    stacks <- files
  }

  # compile xml batch file
  if (is.null(path_template)){
    path_template <- system.file("ZereneBatch.xml", package = "zerenebatchR")
  }

  x <- xml2::read_xml(x = path_template)

  ### add files to source ###

  # x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//Sources") %>% xml_children

  for (file in stacks){
    x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//Sources") %>%
      xml_add_child(paste0('Source value="', file, '"'))
  }

  l <- x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//Sources") %>% xml_children %>% length
  sources <- x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//Sources")
  xml_attr(sources, "length") <- as.character(l)

  # set path out

  x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//OutputImagesDesignatedFolder") %>%
    xml_replace(paste0('OutputImagesDesignatedFolder value="', fs::path_expand(path_out), '"'))

  # set stacking algorithm

  stacker <- switch(stacker,
                    "pmax" = "PMax",
                    "dmap" = "DMap")

  x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//Slabbing.StackingOperation") %>%
    xml_replace(paste0('Slabbing.StackingOperation value="', stacker, '"'))

  # write batch file

  if (is.null(path_xml)){
    path_xml <- paste0(path_out, "batchfile_", strftime(Sys.time(),
                                                        format = "%Y-%m-%d_%H-%M-%S"), ".xml")
  }

  write_xml(x, file = path_xml)

  # run batch file

  system(paste0(launch_cmd,
                " -noSplashScreen -runMinimized -exitOnBatchScriptCompletion -batchScript ",
                path_xml))

  # delete temp folders

  if (temp){
    fs::dir_delete(stacks)
  }
}

#' Stack files in folders
#' @importFrom fs dir_create file_copy file_move
#' @param df data.frame containing at least 2 columns containing the paths of
#' the files to parse and a grouping factor.
#' @param c_path String or numerical index specifying column where paths can be found.
#' @param c_split String or numerical index specifying column where factor can
#' be found for grouping images.
#' @param temp Logical. If TRUE, the function will stack files into a temp
#' directory which will be deleted when the operation is completed. Thus,
#' the organization of the original image files will be maintained. Otherwise,
#' images will be moved permanently into new folders according to the provided
#' grouping variable. Defaults to TRUE.
#' @author Ethan Bass

stack_files <- function(df, c_path, c_split, temp = TRUE){

  if (length(c_split) > 1){
    df$id <-apply(df[, c_split], MARGIN = 1, function(x) paste(x, collapse = "-"))
  } else{
    df$id <- df[, c_split]
  }

  df <- split(as.data.frame(df), df[, "id"])
  file_action <- switch(as.character(temp),
                        "TRUE" = fs::file_copy,
                        "FALSE" = fs::file_move)
  paths <- sapply(df, function(x){
    if (any(fs::file_exists(x[, c_path]))){
      path <- x[1, c_path]
      dirn <- dirname(path)
      dirn <- ifelse(temp, fs::path(dirn, "temp"), dirn)
      dir_path <- fs::path(dirn, x[, "id"][1])
      fs::dir_create(dir_path)
      sapply(x[,c_path], function(file){
        try(file_action(file, dir_path))
      })
      dir_path
    } else{
      warning(paste0("Skipping stack ", sQuote(x[1, "id"]), ". Files not found."))
      NA
    }
  })
  if (any(is.na(paths))){
    paths <- paths[which(!is.na(paths))]
  }
  paths
}
