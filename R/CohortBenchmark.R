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


#' Generate predefined set of cohorts
#' @param connectionDetails An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema Fully qualified name of database schema that contains OMOP CDM schema.
#'                          On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param scratchDatabaseSchema Fully qualified name of database schema where temporary tables can be written.
#' @returns list of DED diagnostics_summary and duration
.runCohortBenchmark <- function(
  connectionDetails,
  cdmDatabaseSchema,
  scratchDatabaseSchema
) {
  # Connect to the database with CDMConnector
  connection <- .getCdmConnection(connectionDetails)

  on.exit(.disconnectCdmConnection(connection))

  cdm <- CDMConnector::cdmFromCon(
    connection,
    cdmSchema = cdmDatabaseSchema,
    writeSchema = scratchDatabaseSchema,
    .softValidation = TRUE
  )

  cohort_set_definition <- CDMConnector::readCohortSet(
    path = system.file("json", "cohorts", package = "CdmOnboarding", mustWork = TRUE)
  )
  n_cohorts <- nrow(cohort_set_definition)

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
          cohort_set_definition[i, ],
          name = "cohort",
          compute_attrition = FALSE,
          overwrite = TRUE
        )
      ))
      cohort_count <- CDMConnector::cohortCount(cdm$cohort)
      ParallelLogger::logInfo("Generated: ", cohort_set_definition[[i, 'cohort_name']])
      cohort_count
    }, error = function(e) {
      ParallelLogger::logInfo("Error in generating: ", cohort_set_definition[[i, 'cohort_name']])
      e
    })
    delta <- as.numeric(difftime(Sys.time(), start_time), units = "secs")

    if (inherits(result, "error")) {
      n_records <- c(n_records, NA)
      n_subjects <- c(n_subjects, NA)
      duration <- c(duration, delta)
      error <- c(error, result$message)
      next
    } else {
      n_records <- c(n_records, result$number_records)
      n_subjects <- c(n_subjects, result$number_subjects)
      duration <- c(duration, delta)
      error <- c(error, NA)
    }
  }

  n_subject_bins <- cut(as.integer(n_subjects), breaks = c(0, 100, 1000, 10000, 100000, 1000000, Inf), labels = c("0-100", "100-1k", "1k-10k", "10k-100k", "100k-1M", "1M+"))

  data.frame(
    cohort_name = cohort_set_definition$cohort_name,
    n_subject_bins = n_subject_bins,
    duration = duration,
    error = error
  )
}
