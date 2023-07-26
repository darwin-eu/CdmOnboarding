# @file PerformanceChecks.R
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


#' The performane checks (for v5.x)
#'
#' @description
#' \code{PerformanceChecks} runs a list of performance checks as part of the CDM Onboarding procedure
#'
#' @details
#' \code{PerformanceChecks} runs a list of performance checks as part of the CDM Onboarding procedure
#'
#' @param connectionDetails                An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param resultsDatabaseSchema		         Fully qualified name of database schema that we can write final results to.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_results.dbo'.
#' @param vocabDatabaseSchema		           String name of database schema that contains OMOP Vocabulary.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example 'results.dbo'.
#' @param sqlOnly                          Boolean to determine if Achilles should be fully executed. TRUE = just generate SQL files, don't actually run, FALSE = run Achilles
#' @param outputFolder                     Path to store logs and SQL files
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
performanceChecks <- function(connectionDetails,
                              resultsDatabaseSchema,
                              vocabDatabaseSchema,
                              sqlOnly = FALSE,
                              outputFolder = "output") {
  achillesTiming <- executeQuery(outputFolder, "achilles_timing.sql", "Retrieving duration of Achilles queries",
                                 connectionDetails, sqlOnly, resultsDatabaseSchema = resultsDatabaseSchema)

  performanceBenchmark <- executeQuery(outputFolder, "performance_benchmark.sql", "Executing vocabulary query benchmark",
                                       connectionDetails, sqlOnly, vocabDatabaseSchema = vocabDatabaseSchema)

  list(
    achillesTiming = achillesTiming,
    performanceBenchmark = performanceBenchmark
  )
}

.getDbmsVersion <- function(connectionDetails, outputFolder) {
  versionQuery <- switch(
    connectionDetails$dbms,
    "postgresql" = "SELECT version();",
    "redshift" = "SELECT version();",
    "sql server" = "SELECT @@version;",
    "oracle" = "SELECT * FROM v$version WHERE banner LIKE 'Oracle%';",
    "snowflake" = "SELECT CURRENT_VERSION();"
  )

  errorReportFile <- file.path(outputFolder, "errorDBMSversion.txt")
  versionString <- tryCatch({
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    DatabaseConnector::querySql(
      connection = connection,
      sql = versionQuery,
      progressBar = FALSE,
      reportOverallTime = FALSE,
      errorReportFile = errorReportFile
    )
  },
  error = function(e) {
    ParallelLogger::logWarn("> DBMS version could not be retrieved")
    FALSE
  },
  finally = {
    DatabaseConnector::disconnect(connection = connection)
    rm(connection)
  })
}