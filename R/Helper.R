# @file Helper
#
# Copyright 2022 Darwin EU Coordination Center
#
# This file is part of CdmOnboarding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @author Darwin EU Coordination Center
# @author Peter Rijnbeek
# @author Maxim Moinat

executeQuery <- function(
  outputFolder,
  sqlFileName,
  successMessage,
  connectionDetails = NULL,
  sqlOnly = FALSE,
  activeConnection = NULL,
  useExecuteSql = FALSE,
  ...){
  if (!is.null(connectionDetails)) {
    dbms <- connectionDetails$dbms
  } else {
    dbms <- activeConnection@dbms
  }

  sql <-   do.call(
    SqlRender::loadRenderTranslateSql,
    c(
      sqlFilename = file.path("checks", sqlFileName),
      packageName = "CdmOnboarding",
      dbms = dbms,
      warnOnMissingParameters = FALSE,
      list(...)
    )
  )

  duration <- -1
  result <- NULL
  if (sqlOnly) {
    SqlRender::writeSql(sql = sql, targetFile = file.path(outputFolder, sqlFileName))
    return(list(result=result, duration=duration))
  }

  errorReportFile <- file.path(outputFolder, sprintf("%sErr.txt", tools::file_path_sans_ext(sqlFileName)))
  tryCatch({
    start_time <- Sys.time()

    if (is.null(activeConnection)) {
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    } else {
      connection <- activeConnection
    }

    if (useExecuteSql) {
      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql,
        errorReportFile = errorReportFile,
        reportOverallTime = FALSE
      )
    } else {
      result <- DatabaseConnector::querySql(connection = connection, sql = sql, errorReportFile = errorReportFile)
    }

    duration <- as.numeric(difftime(Sys.time(),start_time), units="secs")
    ParallelLogger::logInfo(sprintf("> %s in %.2f secs", successMessage, duration))
  },
  error = function (e) {
    ParallelLogger::logError(sprintf("%s", e))
    ParallelLogger::logError(sprintf("> Query failed. See '%s' for more details", errorReportFile))
  },
  finally = {
    if (is.null(activeConnection)) {
      DatabaseConnector::disconnect(connection = connection)
      rm(connection)
    }
  })

  return(list(result=result, duration=duration))
}

prettyHr <- function(x) {
  result <- sprintf("%.2f", x)
  result[is.na(x)] <- "NA"
  result <- suppressWarnings(format(as.numeric(result), big.mark=",")) # add thousands separator
  return(result)
}

prettyPc <- function(x) {
  result <- sprintf("%.1f%%", x)
  result[is.na(x)] <- "NA"
  result[x==100] <- "100%"
  result[x==0] <- "0%"
  return(result)
}

my_caption <- function(x, caption, sourceSymbol, style) {
  officer::body_add_par(
    x,
    value = sprintf(
      "%s %s",
      caption,
      sourceSymbol
    ),
    style = style
  )
}

my_body_add_table <- function(x, value, pos = "after", header = TRUE,
          alignment = NULL, stylenames = table_stylenames(), first_row = TRUE,
          first_column = FALSE, last_row = FALSE, last_column = FALSE,
          no_hband = FALSE, no_vband = TRUE, align = "left", auto_format = TRUE)
{
  pt <- officer::prop_table(style = pkg.env$styles$table, layout = officer::table_layout(),
                   width = officer::table_width(), stylenames = stylenames,
                   tcf = officer::table_conditional_formatting(
                     first_row = first_row, first_column = first_column, last_row = last_row,
                     last_column = last_column, no_hband = no_hband, no_vband = no_vband),
                   align = align)

  if (auto_format) {
    # Align left if no alignment is given
    if (is.null(alignment)) {
      alignment <- rep('l', ncol(value))
    }

    # Formatting numeric columns: align right and add thousands separator.
    for (i in seq_len(ncol(value))) {
      if (is.numeric(value[,i])) {
        value[,i] <- format(value[,i], big.mark=",")
        alignment[i] <- 'r'
      }
    }
  }

  bt <- officer::block_table(x = value, header = header, properties = pt,
                    alignment = alignment)
  xml_elt <- officer::to_wml(bt, add_ns = TRUE, base_document = x)
  officer::body_add_xml(x = x, str = xml_elt, pos = pos)
}

my_body_add_table_runtime <- function(x, value, ...)
{
  my_body_add_table(x, value$result, ...) %>%
    officer::body_add_par(sprintf("Query executed in %.2f seconds", value$duration), style = pkg.env$styles$footnote)
}

my_source_value_count_section <- function (x, data, domain, kind, smallCellCount) {
  n <- nrow(data$result)

  msg <- "Counts are rounded up to the nearest hundred."
  if (!is.null(smallCellCount)) {
    msg <- sprintf("%s Values with a record count <=%d are omitted.", msg, smallCellCount)
  }

  caption <- sprintf("Top 25 %s %s. %s", kind, domain, msg)
  if (n == 0) {
    caption <- sprintf("Omitted because no %s %s were found with a count >%d.", kind, domain, smallCellCount)
  } else if (n < 25) {
    caption <- sprintf("All %d %s %s. %s", n, kind, domain, msg)
  }
  x <- my_caption(x, caption, sourceSymbol = pkg.env$sources$cdm, style = pkg.env$styles$tableCaption)

  if (n > 0) {
    data$result$`%Records` <- prettyPc(data$result$`%Records`)
    if (kind == 'unmapped') {
      alignment <- c('r','l','r','r') # #,name,n,%
    } else {
      alignment <- c('r','l','l','r','r') # #,concept_id,name,n,%
    }
    x <- my_body_add_table(
      x,
      value = data$result,
      alignment = alignment
    )
  }

  officer::body_add_par(x, sprintf("Query executed in %.2f seconds", data$duration), style = pkg.env$styles$footnote)
}

my_unmapped_section <- function(x, data, domain, smallCellCount) {
  names(data$result) <- c("#", "Source Value", "#Records", "%Records")
  my_source_value_count_section(x, data, domain, "unmapped", smallCellCount)
}

my_mapped_section <- function(x, data, domain, smallCellCount) {
  names(data$result) <- c("#", "Concept id", "Concept Name", "#Records", "%Records")
  my_source_value_count_section(x, data, domain, "mapped", smallCellCount)
}


recordsCountPlot <- function(results){
  temp <- results %>%
    dplyr::rename(Date=X_CALENDAR_MONTH,Domain=SERIES_NAME, Count=Y_RECORD_COUNT) %>%
    dplyr::mutate(Date=lubridate::parse_date_time(Date, "ym"))
  plot <- ggplot2::ggplot(temp, aes(x = Date, y = Count)) +
    geom_line(aes(color = Domain)) + # , linetype = Domain
    scale_colour_hue(l=40)
}

#' Bundles the results in a zip file
#'
#' @description
#' \code{bundleResults} creates a zip file with results in the outputFolder
#' @param outputFolder  Folder to store the results
#' @param databaseId    ID of your database, this will be used as subfolder for the results.
#' @export
bundleResults <- function(outputFolder, databaseId) {
  zipName <- file.path(outputFolder, paste0("Results_Onboarding_", databaseId, ".zip"))
  files <- list.files(outputFolder, "*.*", full.names = TRUE, recursive = TRUE)
  oldWd <- setwd(outputFolder)
  on.exit(setwd(oldWd), add = TRUE)
  DatabaseConnector::createZipFile(zipFile = zipName, files = files)
  return(zipName)
}
