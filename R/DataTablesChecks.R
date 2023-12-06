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
  if (optimize && connectionDetails$dbms == "postgresql") {
    dataTablesCountQuery <- "data_tables_count_postgres.sql"
  } else if (optimize && connectionDetails$dbms == "sql server") {
    dataTablesCountQuery <- "data_tables_count_sql_server.sql"
  } else if (optimize) {
    dataTablesCountQuery <- "data_tables_count_no_person_count.sql"
  } else {
    dataTablesCountQuery <- "data_tables_count.sql"
  }

  sqlFileNames <- c(
    dataTablesCounts = dataTablesCountQuery,
    totalRecords = "totalrecords.sql",
    recordsPerPerson = "recordsperperson.sql",
    conceptsPerPerson = "conceptsperperson.sql",
    observationPeriodLength = "observation_period_length.sql",
    activePersons = "active_persons.sql",
    observedByMonth = "observed_by_month.sql",
    typeConcepts = "type_concepts.sql",
    tableDateRange = "data_tables_date_range.sql",
    dayOfTheWeek = "day_of_the_week.sql",
    dayOfTheMonth = "day_of_the_month.sql",
    observationPeriodsPerPerson = "observation_periods_per_person.sql",
    observationPeriodOverlap = "observation_period_overlap.sql",
    dayMonthYearOfBirth = "day_month_year_of_birth.sql"
  )

  result <- list()
  for (fieldName in names(sqlFileNames)) {
    sqlFileName <- sqlFileNames[[fieldName]]
    result[[fieldName]] <- executeQuery(
      outputFolder = outputFolder,
      sqlFileName = sqlFileName,
      connectionDetails = connectionDetails,
      sqlOnly = sqlOnly,
      cdmDatabaseSchema = cdmDatabaseSchema,
      vocabDatabaseSchema = vocabDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema
    )
  }

  return(result)
}
