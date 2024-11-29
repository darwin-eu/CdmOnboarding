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


#' The main CDM Onboarding method (for v5.x)
#'
#' @description
#' \code{cdmOnboarding} runs the CDM Onboarding procedure. Executing the checks and outputing a results document
#'
#' @details
#' \code{cdmOnboarding} runs the CDM Onboarding procedure. Executing the checks and outputing a results document
#'
#' @param connectionDetails                An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema    	           Fully qualified name of database schema that contains OMOP CDM schema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param resultsDatabaseSchema		         Fully qualified name of database schema that we can write final results to. Default is cdmDatabaseSchema.
#'                                         The Achilles results are read from this table.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_results.dbo'.
#' @param scratchDatabaseSchema            Fully qualified name of database schema that we can write temporary tables to. Default is resultsDatabaseSchema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_scratch.dbo'.
#' @param oracleTempSchema                 For Oracle only: the name of the database schema where you want all temporary tables to be managed. Requires create/insert permissions to this database.
#' @param databaseId                       ID of your database, this will be used as subfolder for the results and naming of the report
#' @param databaseName		                 String name of the database name. If blank, CDM_SOURCE table will be queried to try to obtain this.
#' @param databaseDescription              Provide a short description of the database. If blank, CDM_SOURCE table will be queried to try to obtain this.
#' @param authors                          List of author names to be added in the document
#' @param runVocabularyChecks              Boolean to determine if vocabulary checks need to be run. Default = TRUE
#' @param runDataTablesChecks              Boolean to determine if table checks need to be run. Default = TRUE
#' @param runWebAPIChecks                  Boolean to determine if WebAPI checks need to be run. Default = TRUE
#' @param runPerformanceChecks             Boolean to determine if performance checks need to be run. Default = TRUE
#' @param runDedChecks                     Boolean to determine if DrugExposureDiagnostics checks need to be run. Default = TRUE
#' @param runCohortBenchmarkChecks         Boolean to determine if CohortBenchMark checks need to be run. Default = TRUE
#' @param smallCellCount                   To avoid patient identifiability, source values with small counts (<= smallCellCount) are deleted. Set to NULL if you don't want any deletions. (default 5)
#' @param baseUrl                          WebAPI url, example: http://server.org:80/WebAPI
#' @param sqlOnly                          If TRUE, queries will be written to file instead of executed. Not supported for DED Checks.
#' @param outputFolder                     Path to store logs and SQL files
#' @param verboseMode                      Boolean to determine if the console will show all execution steps. Default = TRUE
#' @param dqdJsonPath                      Path to the json of the DQD
#' @param optimize                         Boolean to determine if heuristics will be used to speed up execution. Currently only implemented for postgresql databases. Default = FALSE
#' @param dedIngredientIds                 DEPRECATED, default ingredients are always used (`getDedIngredients()`).
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
cdmOnboarding <- function(
  connectionDetails,
  cdmDatabaseSchema,
  resultsDatabaseSchema,
  scratchDatabaseSchema = resultsDatabaseSchema,
  oracleTempSchema = resultsDatabaseSchema,
  databaseId,
  databaseName,
  databaseDescription,
  authors = "",
  runVocabularyChecks = TRUE,
  runDataTablesChecks = TRUE,
  runPerformanceChecks = TRUE,
  runWebAPIChecks = TRUE,
  runDedChecks = TRUE,
  runCohortBenchmarkChecks = TRUE,
  smallCellCount = 5,
  baseUrl = NULL,
  sqlOnly = FALSE,
  outputFolder = "output",
  verboseMode = TRUE,
  dqdJsonPath = NULL,
  optimize = FALSE,
  dedIngredientIds = NULL
) {
  if (missing(databaseId)) {
    stop("Argument databaseId is missing")
  }

  if (!is.null(dedIngredientIds)) {
    warning("Argument `dedIngredientIds` has been deprecated, default ingredient list is used (`getDedIngredients()`).")
  }

  results <- .execute(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    scratchDatabaseSchema = scratchDatabaseSchema,
    oracleTempSchema = oracleTempSchema,
    databaseId = databaseId,
    databaseName = databaseName,
    databaseDescription = databaseDescription,
    runVocabularyChecks = runVocabularyChecks,
    runDataTablesChecks = runDataTablesChecks,
    runPerformanceChecks = runPerformanceChecks,
    runWebAPIChecks = runWebAPIChecks,
    runDedChecks = runDedChecks,
    runCohortBenchmarkChecks = runCohortBenchmarkChecks,
    smallCellCount = smallCellCount,
    baseUrl = baseUrl,
    sqlOnly = sqlOnly,
    outputFolder = outputFolder,
    verboseMode = verboseMode,
    dqdJsonPath = dqdJsonPath,
    optimize = optimize
  )

  if (is.null(results)) {
    return(NULL)
  }

  documentGenerated <- NULL
  if (!sqlOnly) {
    documentGenerated <- tryCatch({
      generateResultsDocument(
        results = results,
        outputFolder = outputFolder,
        authors = authors
      )
      TRUE
    }, error = function(e) {
      ParallelLogger::logError("Could not generate results document: ", e)
      ParallelLogger::logInfo("Results from the checks have been saved as an RDS object to the output folder.")
      FALSE
    })
  }

  if (runDedChecks) {
    tryCatch({
      .exportDedResults(
        results = results,
        outputFolder = outputFolder
      )
    }, error = function(e) {
      ParallelLogger::logError("Could not create DrugExposureDiagnostics csv: ", e)
      ParallelLogger::logInfo("Results from DrugExposureDiagnostics have been saved as an RDS object to the output folder.")
    })
  }

  tryCatch({
    bundledResultsLocation <- bundleResults(outputFolder, databaseId)
    ParallelLogger::logInfo("> All generated CDM Onboarding results are bundled for sharing at: ", bundledResultsLocation)
  }, error = function(e) {
    ParallelLogger::logWarn("> Failed to bundle CDM Onboarding results, no zip bundle has been created: ", e)
  })

  if (!(is.null(documentGenerated) || documentGenerated)) {
    ParallelLogger::logError("CdmOnboarding document generation failed. Please fix any issues or reach out to the DARWIN-EU Coordination Centre.") # nolint
  }

  invisible(results)
}

# The main execution of CDM Onboarding analyses (for v5.x)
# Results are returned as list, and stored as an .rds object in the provided output folder
.execute <- function(
  connectionDetails,
  cdmDatabaseSchema,
  resultsDatabaseSchema,
  scratchDatabaseSchema,
  oracleTempSchema,
  databaseId,
  databaseName,
  databaseDescription,
  runVocabularyChecks,
  runDataTablesChecks,
  runPerformanceChecks,
  runWebAPIChecks,
  runDedChecks,
  runCohortBenchmarkChecks,
  smallCellCount,
  baseUrl,
  sqlOnly,
  outputFolder,
  verboseMode,
  dqdJsonPath,
  optimize
) {
  # Log execution -------------------------------------------------------------------------------------
  ParallelLogger::clearLoggers()
  if (!dir.exists(outputFolder)) {
    dir.create(outputFolder, recursive = TRUE)
  }

  logFileName <- "log_cdmOnboarding.txt"

  if (verboseMode) {
    appenders <- list(
      ParallelLogger::createConsoleAppender(),
      ParallelLogger::createFileAppender(
        layout = ParallelLogger::layoutParallel,
        fileName = file.path(outputFolder, logFileName)
      )
    )
  } else {
    appenders <- list(
      ParallelLogger::createFileAppender(
        layout = ParallelLogger::layoutParallel,
        fileName = file.path(outputFolder, logFileName)
      )
    )
  }

  logger <- ParallelLogger::createLogger(name = "cdmOnboarding",
                                         threshold = "INFO",
                                         appenders = appenders)
  ParallelLogger::registerLogger(logger)

  start_time <- Sys.time()
  ParallelLogger::logInfo(sprintf(
    'Running CdmOnboarding v%s %s',
    packageVersion("CdmOnboarding"),
    if (optimize) "(performance optimized)" else ""
  ))

  # CDM Source ------------------------------------------
  cdmSource <- .getCdmSource(connectionDetails, cdmDatabaseSchema, outputFolder)
  if (is.null(cdmSource)) {
    ParallelLogger::logError(sprintf(
      "A populated cdm_source table is required for CdmOnboarding to run. Are your CDM tables in the '%s' schema?",
      cdmDatabaseSchema
    ))
    return(NULL)
  }

  # Parse cdmVersion to format major.minor (e.g. 5.4)
  cdmVersion <- .parseCdmVersionFromCdmSource(cdmSource)
  ParallelLogger::logInfo(sprintf(
    "Found database '%s' with CDM release date '%s'",
    cdmSource$CDM_SOURCE_NAME,
    cdmSource$CDM_RELEASE_DATE
  ))

  # Get source name from cdm_source if none provided --------------------------------------------
  if (missing(databaseName) && !sqlOnly) {
    databaseName <- cdmSource$CDM_SOURCE_NAME
  }
  if (missing(databaseDescription) && !sqlOnly) {
    databaseDescription <- cdmSource$SOURCE_DESCRIPTION
  }

  # Check version -----------------------------------
  if (compareVersion(a = cdmVersion, b = "5") < 0) {
    ParallelLogger::logError(sprintf(
      "CdmOnboarding has been developed for OMOP CDM v5 and above. 'v%s' was found in the cdm_source table.",
      cdmVersion
    ))
    return(NULL)
  }

  # Check whether Achilles output is available and get Achilles run info ---------------------------------------
  achillesMetadata <- NULL
  if (!sqlOnly) {
    achillesTablesExists <- .checkAchillesTablesExist(connectionDetails, resultsDatabaseSchema)
    achillesMetadata <- .getAchillesMetadata(connectionDetails, resultsDatabaseSchema, outputFolder)
    if (is.null(achillesMetadata) || !achillesTablesExists) {
      ParallelLogger::logError("The output from the Achilles analyses is required.")
      ParallelLogger::logError(sprintf(
        "Please run Achilles first and make sure the resulting Achilles tables are in the given results schema ('%s').",
        resultsDatabaseSchema
      ))
      return(NULL)
    }
    if (utils::compareVersion(achillesMetadata$ACHILLES_VERSION, '1.7') < 1) {
      ParallelLogger::logWarn(sprintf("Results from an outdated Achilles version (v%s) were detected, please consider installing the latest release of Achilles and rerun CdmOnboarding.", achillesMetadata$ACHILLES_VERSION)) #nolint
    }
  }

  # Check whether results for required Achilles analyses is available. Generate soft warning.
  # At least require person, obs. period, condition and drug exposure. Other domains can be empty.
  expectedAnalysisIds <- c(105, 110, 111, 117, 403, 420, 703, 720)
  analysisIdsAvailable <- .getAvailableAchillesAnalysisIds(connectionDetails, resultsDatabaseSchema)
  missingAnalysisIds <- setdiff(expectedAnalysisIds, analysisIdsAvailable)
  if (length(missingAnalysisIds) > 0) {
    ParallelLogger::logWarn(sprintf(
      "Missing Achilles analysis ids in result tables: %s.",
      paste(missingAnalysisIds, collapse = ", ")
    ))
    readline("! If this is expected, press enter to continue. If not, abort (ctrl-c) and rerun Achilles including above analyses.")
  }

  dqdResults <- NULL
  if (is.null(dqdJsonPath)) {
    ParallelLogger::logWarn("No dqdJsonPath specfied, data quality section will be empty.")
  } else {
    dqdResults <- .processDqdResults(dqdJsonPath)
  }

  # Establish folder paths -------------------------------------------------------------------------------------
  if (!dir.exists(outputFolder)) {
    dir.create(path = outputFolder, recursive = TRUE)
  }

  ParallelLogger::logInfo(sprintf("> CDM Onboarding of database %s started (cdm_version=v%s)", databaseName, cdmVersion))

  # data table checks ------------------------------------------------------------------------------------------
  dataTablesResults <- NULL
  if (runDataTablesChecks) {
    ParallelLogger::logInfo("Running Data Table Checks")
    dataTablesResults <- dataTablesChecks(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema,
      cdmVersion = cdmVersion,
      outputFolder = outputFolder,
      sqlOnly = sqlOnly,
      optimize = optimize
    )
  }

  # vocabulary checks ---------------------------------------------------------------------------------------------
  vocabularyResults <- NULL
  if (runVocabularyChecks) {
    ParallelLogger::logInfo("Running Vocabulary Checks")
    vocabularyResults <- vocabularyChecks(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchema,
      smallCellCount = smallCellCount,
      cdmVersion = cdmVersion,
      outputFolder = outputFolder,
      sqlOnly = sqlOnly,
      optimize = optimize
    )
  }

  # performance checks --------------------------------------------------------------------------------------------
  performanceResults <- NULL
  if (runPerformanceChecks) {
    ParallelLogger::logInfo("Running Performance checks")
    performanceResults <- performanceChecks(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema,
      scratchDatabaseSchema = scratchDatabaseSchema,
      cdmVersion = cdmVersion,
      sqlOnly = sqlOnly,
      outputFolder = outputFolder
    )
  }

  # webapi checks --------------------------------------------------------------------------------------------
  webApiVersion <- "unknown"
  if (runWebAPIChecks && !(is.null(baseUrl) || baseUrl == "")) {
    ParallelLogger::logInfo("> Running WebAPIChecks")

    webApiVersion <- tryCatch({
      version <- .getWebApiVersion(baseUrl)
      ParallelLogger::logInfo("> Connected successfully to ", baseUrl)
      ParallelLogger::logInfo("> WebAPI version: ", version)
      version
    }, error = function(e) {
      ParallelLogger::logWarn(sprintf("Could not connect to the WebAPI on '%s':\n%s", baseUrl, e))
      "Failed to reach WebApi"
    })
  }

  # DED checks --------------------------------------------------------------------------------------------
  drugExposureDiagnostics <- NULL
  if (runDedChecks) {
    ParallelLogger::logInfo("> Running DED checks")
    drugExposureDiagnostics <- tryCatch({
      .runDedChecks(
        connectionDetails,
        cdmDatabaseSchema,
        scratchDatabaseSchema
      )
    }, error = function(e) {
      ParallelLogger::logError("DED checks failed: ", e)
      NULL
    })
  }

  # Cohort Benchmark checks -------------------------------------------------------------------------------------
  cohortBenchmark <- NULL
  if (runCohortBenchmarkChecks) {
    ParallelLogger::logInfo("> Running Cohort Benchmark")
    cohortBenchmark <- tryCatch({
      .runCohortBenchmark(
        connectionDetails,
        cdmDatabaseSchema,
        scratchDatabaseSchema
      )
    }, error = function(e) {
      ParallelLogger::logError("Cohort Benchmark failed: ", e)
      NULL
    })
  }

  ParallelLogger::logInfo("> Done.")

  ParallelLogger::logInfo(sprintf(
    "> Complete CdmOnboarding took %.2f minutes",
    as.numeric(difftime(Sys.time(), start_time), units = "mins")
  ))

  # save results
  results <- list(
    executionDate = format(Sys.time(), "%Y-%m-%d %H:%M"),
    executionDuration = as.numeric(difftime(Sys.time(), start_time), units = "secs"),
    cdmOnboardingVersion = packageVersion("CdmOnboarding"),
    databaseId = databaseId,
    databaseName = databaseName,
    databaseDescription = databaseDescription,
    vocabularyResults = vocabularyResults,
    dataTablesResults = dataTablesResults,
    performanceResults = performanceResults,
    webAPIversion = webApiVersion,
    dms = connectionDetails$dbms,
    cdmSource = cdmSource,
    achillesMetadata = achillesMetadata,
    smallCellCount = smallCellCount,
    runWithOptimizedQueries = optimize,
    dqdResults = dqdResults,
    drugExposureDiagnostics = drugExposureDiagnostics,
    cohortBenchmark = cohortBenchmark
  )

  tryCatch({
    saveRDS(results, file.path(outputFolder, sprintf("onboarding_results_%s_%s.rds", databaseId, format(Sys.time(), "%Y%m%d"))))
    ParallelLogger::logInfo("> The CDM Onboarding results have been exported to ", outputFolder)
  }, error = function(e) {
    ParallelLogger::logWarn("> Failed to export CDM Onboarding results object, no rds file has been created: ", e)
  })

  return(results)
}

#' Bundles the results in a zip file
#'
#' @description
#' \code{bundleResults} creates a zip file with results in the outputFolder
#' @param outputFolder  Folder to store the results
#' @param databaseId    ID of your database, this will be used as subfolder for the results.
#' @export
bundleResults <- function(outputFolder, databaseId) {
  zipName <- file.path(outputFolder, sprintf("Results_Onboarding_%s_%s.zip", databaseId, format(Sys.time(), "%Y%m%d")))
  files <- list.files(outputFolder, "*.*", full.names = TRUE, recursive = TRUE)
  oldWd <- setwd(outputFolder)
  on.exit(setwd(oldWd), add = TRUE)
  DatabaseConnector::createZipFile(zipFile = zipName, files = files)
  return(zipName)
}
