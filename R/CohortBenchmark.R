# @file CdmOnboarding
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


#' Generate cohorts
#' @param connectionDetails An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema Fully qualified name of database schema that contains OMOP CDM schema.
#'                          On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param scratchDatabaseSchema Fully qualified name of database schema where temporary tables can be written.
#' @param cohortPath Path to the folder containing cohort definitions in JSON format
#' @returns list of DED diagnostics_summary and duration
runCohortBenchmark <- function(
  connectionDetails,
  cdmDatabaseSchema,
  scratchDatabaseSchema,
  cohortPath = "inst/json/cohorts"
) {
  # Connect to the database. For postgres with DBI, otherwise via DatabaseConnector.
  # TODO: separate out the connection details for postgres and other databases
  if (connectionDetails$dbms == 'postgresql') {
    server_parts <- strsplit(connectionDetails$server(), "/")[[1]]

    connection <- DBI::dbConnect(
      RPostgres::Postgres(),
      dbname = server_parts[2],
      host = server_parts[1],
      user = connectionDetails$user(),
      password = connectionDetails$password()
    )
  } else {
    connection <- DatabaseConnector::connect(connectionDetails)
  }

  cdm <- CDMConnector::cdm_from_con(
    connection,
    cdm_schema = cdmDatabaseSchema,
    write_schema = scratchDatabaseSchema,
    .soft_validation = TRUE
  )

  cohortSetDefinition <- CDMConnector::readCohortSet(cohortPath)
  n_cohorts <- nrow(cohortSetDefinition)

  # Generate each cohort definition one by one to capture time taken and possible errors
  n_records <- c()
  n_subjects <- c()
  duration <- c()
  error <- c()
  for (i in seq(1, n_cohorts)) {
    start_time <- Sys.time()
    result <- tryCatch({
      suppressWarnings(suppressMessages(
        cdm <- CDMConnector::generateCohortSet(
          cdm,
          cohortSetDefinition[i, ],
          name = "cohort",
          computeAttrition = FALSE,
          overwrite = TRUE
        )
      ))
      ParallelLogger::logInfo(sprintf("Generated: %s", cohortSetDefinition[[i, 'cohort_name']]))
      cohortCount(cdm$cohort)
    }, error = function(e) {
      ParallelLogger::logInfo(sprintf("Error in generating: %s", cohortSetDefinition[[i, 'cohort_name']]))
      e
    })
    duration <- as.numeric(difftime(Sys.time(), start_time), units = "secs")

    if (inherits(result, "error")) {
      n_records <- c(n_records, NA)
      n_subjects <- c(n_subjects, NA)
      duration <- c(duration, duration)
      error <- c(error, result$message)
      next
    } else {
      n_records <- c(n_records, result$number_records)
      n_subjects <- c(n_subjects, result$number_subjects)
      duration <- c(duration, duration)
      error <- c(error, NA)
    }
  }

  data.frame(
    cohort_name = cohortSetDefinition$cohort_name,
    n_records = n_records,
    n_subjects = n_subjects,
    duration = duration,
    error = error
  )
}