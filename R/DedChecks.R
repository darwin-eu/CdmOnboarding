# @file DedChecks
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
# @author Maxim Moinat

#' Run DrugExposureDiagnostics for a set of default ingredient concepts
#' @param connectionDetails An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema Fully qualified name of database schema that contains OMOP CDM schema.
#'                          On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param scratchDatabaseSchema Fully qualified name of database schema where temporary tables can be written.
#' @returns list of DED diagnostics_summary and duration
.runDedChecks <- function(
  connectionDetails,
  cdmDatabaseSchema,
  scratchDatabaseSchema
) {
  dedIngredients <- getDedIngredients()
  dedIngredientIds <- dedIngredients$concept_id

  ParallelLogger::logInfo(sprintf(
    "Starting execution of DrugExposureDiagnostics for %s ingredients",
    length(dedIngredientIds)
  ))

  # Connect to the database. For postgres with DBI, otherwise via DatabaseConnector.
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
    write_schema = scratchDatabaseSchema
  )

  tryCatch({
    ded_start_time <- Sys.time()

    # Reduce output lines by suppressing both warnings and messages. Only progress bars displayed.
    suppressWarnings(suppressMessages(
      dedResults <- DrugExposureDiagnostics::executeChecks(
        cdm = cdm,
        ingredients = dedIngredientIds,
        checks = c("missing", "exposureDuration", "type", "route", "dose", "quantity", "diagnosticsSummary"),
        minCellCount = 5,
        sample = 1e+06,
        earliestStartDate = "2010-01-01"
      )
    ))

    duration <- as.numeric(difftime(Sys.time(), ded_start_time), units = "secs")
    ParallelLogger::logInfo(sprintf("Executing DrugExposureDiagnostics took %.2f seconds.", duration))

    # Return result with duration
    list(result = dedResults$diagnosticsSummary, duration = duration, packageVersion = packageVersion(pkg = "DrugExposureDiagnostics"))
  }, error = function(e) {
    ParallelLogger::logError("Execution of DrugExposureDiagnostics failed: ", e)
    NULL
  }, finally = {
    if (connectionDetails$dbms == 'postgresql') {
      DBI::dbDisconnect(connection)
    } else {
      DatabaseConnector::disconnect(connection)
    }
    rm(connection)
  })
}

#' Returns data frame with concept_id and concept_name of drug ingredients
#' used for the DrugExposureDiagnostics check
#' @export
getDedIngredients <- function() {
  dedIngredients <- data.frame(
    concept_id = c(
      528323,
      954688,
      968426,
      1119119,
      1125315,
      1139042,
      1140643,
      1154343,
      1550557,
      1703687,
      40225722
    ),
    concept_name = c(
      "hepatitis B surface antigen vaccine",
      "latanoprost",
      "mesalamine",
      "adalimumab",
      "acetaminophen",
      "acetylcysteine",
      "sumatriptan",
      "albuterol",
      "prednisolone",
      "acyclovir",
      "ulipristal"
    )
  )
  return(dedIngredients)
}
