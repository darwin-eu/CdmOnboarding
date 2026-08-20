# @file AchillesHelper.R
#
# Copyright 2026 Darwin EU Coordination Center
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

#' Achilles tables can be queried AND contain data
#' @param connection An R object of type \code{DatabaseConnectorDbiConnection}
#' @param resultsDatabaseSchema Fully qualified name of database schema that holds the the Achilles results.
.checkAchillesTablesExist <- function(connection, resultsDatabaseSchema) {
  required_achilles_tables <- c("achilles_results", "achilles_results_dist")

  achilles_tables_exist <- TRUE
  for (table in required_achilles_tables) {
    sql_rendered <- SqlRender::render(
      "SELECT COUNT(*) AS n FROM @schema.@table",
      schema = resultsDatabaseSchema,
      table = table
    )

    sql_translated <- SqlRender::translate(sql_rendered, targetDialect = connection@dbms)

    result <- tryCatch({
      df <- DatabaseConnector::querySql(connection, sql_translated, snakeCaseToCamelCase = TRUE)
      df$n[1]
    }, error = function(e) {
      NA
    })

    if (is.na(result)) {
      ParallelLogger::logWarn(sprintf(
        "Achilles table '%s.%s' has not been found.",
        resultsDatabaseSchema,
        table
      ))
      achilles_tables_exist <- FALSE
    } else if (result == 0) {
      ParallelLogger::logWarn(sprintf(
        "Achilles table '%s.%s' is empty.",
        resultsDatabaseSchema,
        table
      ))
      achilles_tables_exist <- FALSE
    }
  }
  return(achilles_tables_exist)
}

.getAchillesMetadata <- function(connection, resultsDatabaseSchema, outputFolder) {
  achillesMetadata <- executeQuery(
    outputFolder = outputFolder,
    sqlFileName = "get_achilles_metadata.sql",
    connection = connection,
    resultsDatabaseSchema = resultsDatabaseSchema,
    successMessage = "Achilles metadata successfully extracted"
  )
  achillesMetadata <- achillesMetadata$result

  if (nrow(achillesMetadata) > 1) {
    ParallelLogger::logWarn("Multiple records found for same analysis in achilles_results table. The first record is used.") # nolint
    achillesMetadata <- achillesMetadata[1, ]
  } else if (nrow(achillesMetadata) == 0) {
    ParallelLogger::logError("No record for analysis_id 0 found in the achilles_results table. Please run Achilles first.") # nolint
    return(NULL)
  }

  return(achillesMetadata)
}

.getAvailableAchillesAnalysisIds <- function(connection, resultsDatabaseSchema, outputFolder) {
  achillesAnalyses <- executeQuery(
    outputFolder = outputFolder,
    sqlFolder = "./",
    sqlFileName = "getAchillesAnalyses.sql",
    connection = connection,
    results_database_schema = resultsDatabaseSchema
  )

  return(achillesAnalyses$result$ANALYSIS_ID)
}
