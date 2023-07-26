# @file DataTablesCheck
#
# Copyright 2023 Darwin EU Coordination Center
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


#' The Data Tables checks (for v5.x)
#'
#' @description
#' \code{dataTablesChecks} runs a list of checks on the clinical data tables as part of the CDM Onboarding procedure
#'
#' @details
#' \code{dataTablesChecks} runs a list of checks on the clinical data tables as part of the CDM Onboarding procedure
#'
#' @param connectionDetails                An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema    	           Fully qualified name of database schema that contains OMOP CDM schema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param resultsDatabaseSchema		         Fully qualified name of database schema that we can write final results to.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_results.dbo'.
#' @param vocabDatabaseSchema		           String name of database schema that contains OMOP Vocabulary. Default is cdmDatabaseSchema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example 'results.dbo'.
#' @param cdmVersion                       Define the OMOP CDM version used: currently supports v5 and above.
#'                                         Use major release number or minor number only (e.g. 5, 5.3)
#' @param sqlOnly                          Boolean to determine if Achilles should be fully executed. TRUE = just generate SQL files, don't actually run, FALSE = run Achilles
#' @param outputFolder                     Path to store logs and SQL files
#' @param optimize                         Boolean to determine if heuristics will be used to speed up execution. Currently only implemented for postgresql databases. Default = FALSE
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
dataTablesChecks <- function(connectionDetails,
                              cdmDatabaseSchema,
                              resultsDatabaseSchema,
                              vocabDatabaseSchema = cdmDatabaseSchema,
                              cdmVersion,
                              sqlOnly = FALSE,
                              outputFolder = "output",
                              optimize = FALSE) {
  if (optimize) {
    if (connectionDetails$dbms == "postgresql") {
      dataTablesCounts <- executeQuery(outputFolder, "data_tables_count_postgres.sql", "Data tables (postgres estimate) count query executed successfully",
                                       connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema)
    } else if (optimize && connectionDetails$dbms == "sql server") {
      dataTablesCounts <- executeQuery(outputFolder, "data_tables_count_sql_server.sql", "Data tables (sql server estimate) count query executed successfully",
                                       connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema)
    } else {
      dataTablesCounts <- executeQuery(outputFolder, "data_tables_count_no_person_count.sql", "Data tables (no person count) count query executed successfully",
                                       connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema)
    }
  } else {
    dataTablesCounts <- executeQuery(outputFolder, "data_tables_count.sql", "Data tables count query executed successfully",
                                     connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema, cdmVersion = cdmVersion)
  }

  totalRecords <- executeQuery(outputFolder, "totalrecords.sql", "Total number of records over time query executed successfully",
                               connectionDetails, sqlOnly, resultsDatabaseSchema = resultsDatabaseSchema)
  recordsPerPerson <- executeQuery(outputFolder, "recordsperperson.sql", "Number of records per person query executed successfully",
                                   connectionDetails, sqlOnly, resultsDatabaseSchema = resultsDatabaseSchema)
  conceptsPerPerson <- executeQuery(outputFolder, "conceptsperperson.sql", "Number of records per person query executed successfully",
                                    connectionDetails, sqlOnly, resultsDatabaseSchema = resultsDatabaseSchema)
  observationPeriodLength <- executeQuery(outputFolder, "observation_period_length.sql", "Observation Period length query executed successfully",
                                          connectionDetails, sqlOnly, resultsDatabaseSchema = resultsDatabaseSchema)
  activePersons <- executeQuery(outputFolder, "active_persons.sql", "Active persons query executed successfully",
                                connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema)
  observedByMonth <- executeQuery(outputFolder, "observed_by_month.sql", "Observed by month query executed successfully",
                                  connectionDetails, sqlOnly, resultsDatabaseSchema = resultsDatabaseSchema)
  typeConcepts <- executeQuery(outputFolder, "type_concepts.sql", "Type concept query executed successfully",
                               connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema, vocabDatabaseSchema = vocabDatabaseSchema)
  tableDateRange <- executeQuery(outputFolder, "data_tables_date_range.sql", "Date range query executed successfully",
                                 connectionDetails, sqlOnly, resultsDatabaseSchema = resultsDatabaseSchema)

  list(
    dataTablesCounts = dataTablesCounts,
    totalRecords = totalRecords,
    recordsPerPerson = recordsPerPerson,
    conceptsPerPerson = conceptsPerPerson,
    observationPeriodLength = observationPeriodLength,
    activePersons = activePersons,
    observedByMonth = observedByMonth,
    typeConcepts = typeConcepts,
    tableDateRange = tableDateRange
  )
}
