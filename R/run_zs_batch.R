globalVariables(c("."))

#' create and run batchscript in zerene stacker
#' @import xml2
#' @import magrittr
#' @importFrom fs dir_delete path_home
#' @param files data.frame containing at least 2 columns containing the paths of
#' the files to parse and a grouping factor.
#' @param c_path String or numerical index specifying column where paths can be found.
#' @param c_split String or numerical index specifying column where factor can
#' be found for grouping images
#' @param path_out directory to export converted files.
#' @param stacker Which stacking algorithm to use. Either \code{pmax} or \code{dmap}.
#' @param temp Logical. If TRUE, the function will stack files into a temp
#' directory which will be deleted when the operation is completed. Thus,
#' the organization of the original image files will be maintained. Otherwise,
#' images will be moved into folders by stack.
#' @return If \code{return_paths} is TRUE, the function will return a vector of paths to the newly created files.
#' If \code{return_paths} is FALSE and \code{export_format} is \code{csv}, the function will return a list
#' of chromatograms in \code{data.frame} format. Otherwise, it will not return anything.
#' @section Side effects: Chromatograms will be exported in the format specified
#' by \code{export_format} in the folder specified by \code{path_out}.
#' @author Ethan Bass
#' @export


run_zs_batch <- function(files, c_path = 1, c_split = 2,
                               path_out, stacker = c("pmax", "dmap"),
                               temp = TRUE){
  if (nrow(files) == 0){
    stop("Files not found.")
  }
  stacker <- match.arg(stacker, c("pmax", "dmap"))
  if (missing(path_out)){
    temp <- TRUE
  }

  # if(!file.exists(path_out)){
  #   stop("'path_out' not found. Make sure directory exists.")
  # }

  system <- .Platform$OS.type

  # stack files in temporary folders

  stacks <- stack_files(files, c_path, c_split, temp=temp)

  # get launch command
  # program_path <- configure_zerene_stacker()

  launch_cmd_path <- switch(system,
                            "unix" = path_home("Library/Preferences/ZereneStacker/zerenstk.launchcmd"),
                            "windows" = path_home("AppData\\ZereneStacker\\zerenstk.launchcmd"),
                            "linux" = "~/.ZereneStacker/zerenstk.launchcmd"
                            )

  launch_cmd <- readLines(launch_cmd_path)

  # compile xml batch file

  path_template <- system.file("ZereneBatch.xml", package = "zerenebatchR")
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
  # x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//Sources")

  # set path out
  # <OutputImagesDesignatedFolder value="/Users/ethanbass/Pictures/mycorrhizal_competition_pics/2022_10_01/stacked" />

  x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//OutputImagesDesignatedFolder") %>%
    xml_replace(paste0('OutputImagesDesignatedFolder value="', path_out, '"'))
  # x %>% xml_children %>% .[[4]] %>% xml_add_child(.value=gsub("path_out", path_out, parser))

  # set stacking algorithm
  # <Slabbing.StackingOperation value="PMax" />

  stacker <- switch(stacker,
                    "pmax" = "PMax",
                    "dmap" = "DMap")
  x %>% xml_children()  %>% .[[2]] %>% xml_find_all("//Slabbing.StackingOperation") %>%
    xml_replace(paste0('Slabbing.StackingOperation value="', stacker, '"'))

  # write batch file

  path_xml <- paste0(path_out, "batchfile_", strftime(Sys.time(),format = "%Y-%m-%d_%H-%M-%S"), ".xml")
  write_xml(x, file = path_xml)

  # run batch file

  system(paste0(launch_cmd,
                " -noSplashScreen -runMinimized -exitOnBatchScriptCompletion -batchScript ",
                path_xml))
  # , " -sourcePath=", path

  # delete temp folders

  if (temp){
    dir_delete(stacks)
  }
}

#' stack files in folders
#' @importFrom fs dir_create file_copy file_move
#' @param files data.frame containing at least 2 columns containing the paths of
#' the files to parse and a grouping factor.
#' @param c_path String or numerical index specifying column where paths can be found.
#' @param c_split String or numerical index specifying column where factor can
#' be found for grouping images.
#' @param temp Logical. If TRUE, the function will stack files into a temp
#' directory which will be deleted when the operation is completed. Thus,
#' the organization of the original image files will be maintained. Otherwise,
#' images will be moved into folders by stack.
#' @author Ethan Bass
stack_files <- function(files, c_path, c_split, temp = TRUE){
  sep <- "/"
  df <- split(as.data.frame(files), files[,c_split])
  sapply(df, function(x){
    path <- x[1, c_path]
    dirn <- dirname(path)
    dirn <- ifelse(temp, paste0(dirn, "/temp/"), dirn)
    dir_path <- paste(dirn, x[,c_split][1], sep=sep)
    dir_create(dir_path)
    file_action <- switch(temp,
                          "TRUE" = file_copy,
                          "FALSE" = file_move)
    sapply(x[,c_path], function(file){
      file_action(file, dir_path)
    })
    dir_path
  })
}
