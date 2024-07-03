# @file AchillesHelper.R
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
# @author Maxim Moinat

.checkAchillesTablesExist <- function(connectionDetails, resultsDatabaseSchema) {
  required_achilles_tables <- c("achilles_analysis", "achilles_results", "achilles_results_dist")

  connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection = connection))

  achilles_tables_exist <- TRUE
  for (table in required_achilles_tables) {
    table_exists <- DatabaseConnector::existsTable(connection, resultsDatabaseSchema, table)
    if (!table_exists) {
      ParallelLogger::logWarn(
        sprintf("Achilles table '%s.%s' has not been found", resultsDatabaseSchema, table)
      )
    }
    achilles_tables_exist <- achilles_tables_exist && table_exists
  }

  return(achilles_tables_exist)
}

.getAchillesMetadata <- function(connectionDetails, resultsDatabaseSchema, outputFolder) {
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = file.path("checks", "get_achilles_metadata.sql"),
    packageName = "CdmOnboarding",
    dbms = connectionDetails$dbms,
    warnOnMissingParameters = FALSE,
    resultsDatabaseSchema = resultsDatabaseSchema
  )

  errorReportFile <- file.path(outputFolder, "getAchillesMetadataError.txt")
  achillesMetadata <- tryCatch({
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    achillesMetadata <- DatabaseConnector::querySql(
      connection = connection,
      sql = sql,
      errorReportFile = errorReportFile
    )
    if (nrow(achillesMetadata) > 1) {
      ParallelLogger::logWarn("Multiple records found for same analysis in achilles_results table. The first record is used.") # nolint
      achillesMetadata <- achillesMetadata[1, ]
    } else if (nrow(achillesMetadata) == 0) {
      ParallelLogger::logError("No record for analysis_id 0 found in the achilles_results table. Please run Achilles first.") # nolint
      return(NULL)
    }
    ParallelLogger::logInfo("> Achilles metadata successfully extracted")
    achillesMetadata
  },
  error = function(e) {
    ParallelLogger::logError(sprintf(
      "> Achilles metadata could not be extracted, see %s for more details",
      errorReportFile
    ))
    NULL
  },
  finally = {
    DatabaseConnector::disconnect(connection = connection)
    rm(connection)
  })
  return(achillesMetadata)
}

.getAvailableAchillesAnalysisIds <- function(connectionDetails, resultsDatabaseSchema) {
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "getAchillesAnalyses.sql",
    packageName = "CdmOnboarding",
    dbms = connectionDetails$dbms,
    results_database_schema = resultsDatabaseSchema
  )

  connection <- DatabaseConnector::connect(connectionDetails)
  result <- tryCatch({
    DatabaseConnector::querySql(
      connection = connection,
      sql = sql
    )
  }, error = function(e) {
    ParallelLogger::logError("Could not get available achilles analyses")
    ParallelLogger::logError(e)
  }, finally = {
    DatabaseConnector::disconnect(connection = connection)
    rm(connection)
  })
  result$ANALYSIS_ID
}
