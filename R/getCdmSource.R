# @file getCdmSource.R
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


#' Get CDM source table
#' @param connectionDetails                An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema    	           Fully qualified name of database schema that contains OMOP CDM schema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param outputFolder                     Path to store logs and SQL files
#' @return                                 A data frame with the CDM source table
.getCdmSource <- function(
  connectionDetails,
  cdmDatabaseSchema,
  outputFolder
) {
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = file.path("checks", "get_cdm_source_table.sql"),
    packageName = "CdmOnboarding",
    dbms = connectionDetails$dbms,
    warnOnMissingParameters = FALSE,
    cdmDatabaseSchema = cdmDatabaseSchema
  )

  errorReportFile <- file.path(outputFolder, "cdmSourceError.txt")
  cdmSource <- tryCatch({
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    cdmSource <- DatabaseConnector::querySql(connection = connection, sql = sql, errorReportFile = errorReportFile)
    if (nrow(cdmSource) > 1) {
      ParallelLogger::logWarn("Multiple records found in the cdm_source table. The first record is used.")
      cdmSource <- cdmSource[1, ]
    }
    if (nrow(cdmSource) == 0) {
      stop("No records found in the cdm_source table. Please populate the table.")
    }
    ParallelLogger::logInfo("> CDM Source table successfully extracted")
    cdmSource
  }, error = function(e) {
    ParallelLogger::logError(sprintf(
      "> CDM Source table could not be extracted, see %s for more details",
      errorReportFile
    ))
    NULL
  }, finally = {
    DatabaseConnector::disconnect(connection = connection)
    rm(connection)
  })

  # Format as date
  cdmSource$CDM_RELEASE_DATE <- as.character(cdmSource$CDM_RELEASE_DATE)
  cdmSource$SOURCE_RELEASE_DATE <- as.character(cdmSource$SOURCE_RELEASE_DATE)

  return(cdmSource)
}

# Parse cdmVersion to format major.minor (e.g. 5.4)
.parseCdmVersionFromCdmSource <- function(cdmSource) {
  cdmVersion <- gsub(pattern = "v", replacement = "", cdmSource$CDM_VERSION)
  cdmVersion <- substr(cdmVersion, 1, 3)
  return(cdmVersion)
}