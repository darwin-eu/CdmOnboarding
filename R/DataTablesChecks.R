# @file DataTablesCheck
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


#' The vocabulary checks (for v5.x)
#'
#' @description
#' \code{CdmOnboarding} runs a list of checks on the vocabulary as part of the CDM Onboarding procedure
#'
#' @details
#' \code{CdmOnboarding} runs a list of checks on the vocabulary as part of the CDM Onboarding procedure
#'
#' @param connectionDetails                An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema    	           Fully qualified name of database schema that contains OMOP CDM schema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param resultsDatabaseSchema		         Fully qualified name of database schema that we can write final results to. Default is cdmDatabaseSchema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_results.dbo'.
#' @param vocabDatabaseSchema		           String name of database schema that contains OMOP Vocabulary. Default is cdmDatabaseSchema. On SQL Server, this should specifiy both the database and the schema, so for example 'results.dbo'.
#' @param oracleTempSchema                 For Oracle only: the name of the database schema where you want all temporary tables to be managed. Requires create/insert permissions to this database.
#' @param sourceName		                   String name of the data source name. If blank, CDM_SOURCE table will be queried to try to obtain this.
#' @param sqlOnly                          Boolean to determine if Achilles should be fully executed. TRUE = just generate SQL files, don't actually run, FALSE = run Achilles
#' @param outputFolder                     Path to store logs and SQL files
#' @param verboseMode                      Boolean to determine if the console will show all execution steps. Default = TRUE
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
dataTablesChecks <- function (connectionDetails,
                              cdmDatabaseSchema,
                              resultsDatabaseSchema = cdmDatabaseSchema,
                              vocabDatabaseSchema = cdmDatabaseSchema,
                              oracleTempSchema = resultsDatabaseSchema,
                              cdmVersion = "5.3",
                              sourceName = "",
                              sqlOnly = FALSE,
                              outputFolder = "output",
                              verboseMode = TRUE) {
  dataTablesCounts <- executeQuery(outputFolder,"data_tables_count.sql", "Data tables count query executed successfully", connectionDetails, sqlOnly, cdmDatabaseSchema, vocabDatabaseSchema, resultsDatabaseSchema, cdmVersion)
  totalRecords <- executeQuery(outputFolder,"totalrecords.sql", "Total number of records over time query executed successfully", connectionDetails, sqlOnly, cdmDatabaseSchema, vocabDatabaseSchema, resultsDatabaseSchema)
  recordsPerPerson <- executeQuery(outputFolder,"recordsperperson.sql", "Number of records per person query executed successfully", connectionDetails, sqlOnly, cdmDatabaseSchema, vocabDatabaseSchema, resultsDatabaseSchema)
  conceptsPerPerson <- executeQuery(outputFolder,"conceptsperperson.sql", "Number of records per person query executed successfully", connectionDetails, sqlOnly, cdmDatabaseSchema, vocabDatabaseSchema, resultsDatabaseSchema)

  results <- list(dataTablesCounts=dataTablesCounts,
                  totalRecords=totalRecords,
                  recordsPerPerson=recordsPerPerson,
                  conceptsPerPerson=conceptsPerPerson)
  return(results)
}
