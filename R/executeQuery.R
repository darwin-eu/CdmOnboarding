# @file executeQuery.R
#
# Copyright 2024 Darwin EU Coordination Center
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

#' Execute sql file on the given connectionDetails
#' @param outputFolder                     Path to store logs and SQL files
#' @param sqlFileName                      Name of the SQL file to execute
#' @param successMessage                   Message to log when the query is successful
#' @param connectionDetails                An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param sqlOnly                          Boolean indicating if only the SQL should be written to file
#' @param activeConnection                 An active connection object to use
#' @param useExecuteSql                    Boolean indicating if the query should be executed using \code{executeSql} instead of \code{querySql}
#' @param ...                              Additional parameters to pass to SqlRender::loadRenderTranslateSql
#' @returns result of the query
executeQuery <- function(
  outputFolder,
  sqlFileName,
  successMessage = NULL,
  connectionDetails = NULL,
  sqlOnly = FALSE,
  activeConnection = NULL,
  useExecuteSql = FALSE,
  ...) {
  if (!is.null(connectionDetails)) {
    dbms <- connectionDetails$dbms
  } else {
    dbms <- activeConnection@dbms
  }

  if (is.null(successMessage)) {
    successMessage <- sprintf("'%s' executed successfully", sqlFileName)
  }

  sql <- do.call(
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
    return(list(result = result, duration = duration))
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
      result <- DatabaseConnector::querySql(
        connection = connection,
        sql = sql,
        errorReportFile = errorReportFile
      )
    }

    duration <- as.numeric(difftime(Sys.time(), start_time), units = "secs")
    ParallelLogger::logInfo(sprintf("> %s in %.2f secs", successMessage, duration))
  },
  error = function(e) {
    ParallelLogger::logError(e)
    ParallelLogger::logError(sprintf("> Query failed. See '%s' for more details", errorReportFile))
  },
  finally = {
    if (is.null(activeConnection)) {
      DatabaseConnector::disconnect(connection = connection)
      rm(connection)
    }
  })

  return(list(result = result, duration = duration))
}
