# @file CdmOnboarding
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
#' @param connectionDetails                An R object of type \code{ConnectionDetails} or \code{DbiConnectionDetails} created using the function \code{createDbiConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmSchema    	                   Fully qualified name of database schema that contains OMOP CDM schema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param resultsSchema		                 Fully qualified name of database schema that holds the the Achilles results.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_results.dbo'.
#' @param writeSchema                      Fully qualified name of database schema that we can write temporary tables to. Default is resultsDatabaseSchema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_scratch.dbo'.
#' @param databaseId                       ID of your database, this will be used as subfolder for the results and naming of the report
#' @param databaseName		                 String name of the database name. If blank, CDM_SOURCE table will be queried to try to obtain this.
#' @param databaseDescription              Provide a short description of the database. If blank, CDM_SOURCE table will be queried to try to obtain this.
#' @param authors                          List of author names to be added in the document
#' @param runVocabularyChecks              Boolean to determine if vocabulary checks need to be run. Default = TRUE
#' @param runDataTablesChecks              Boolean to determine if table checks need to be run. Default = TRUE
#' @param runWebAPIChecks                  Boolean to determine if WebAPI checks need to be run. Default = TRUE
#' @param runPerformanceChecks             Boolean to determine if performance checks need to be run. Default = TRUE
#' @param runDedChecks                     Boolean to determine if DrugExposureDiagnostics checks need to be run. Default = TRUE
#' @param runDataHashByTable               Boolean to determine if CdmDataHashByTable need to be run. Default = TRUE
#' @param smallCellCount                   To avoid patient identifiability, source values with small counts (<= smallCellCount) are deleted. Set to NULL if you don't want any deletions. (default 5)
#' @param baseUrl                          WebAPI url, example: http://server.org:80/WebAPI
#' @param outputFolder                     Path to store logs and SQL files
#' @param verboseMode                      Boolean to determine if the console will show all execution steps. Default = TRUE
#' @param dqdJsonPath                      Path to the json of the DQD
#' @param optimize                         Boolean to determine if heuristics will be used to speed up execution. Currently only implemented for postgresql databases. Default = FALSE
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @examples
#' \dontrun{
#' # Postgres
#' connectionDetails <- DatabaseConnector::createDbiConnectionDetails(
#'   dbms = "postgresql",
#'   drv = RPostgres::Postgres(),
#'   dbname = Sys.getenv("CDM5_POSTGRESQL_DBNAME"),
#'   host = Sys.getenv("CDM5_POSTGRESQL_HOST"),
#'   user = Sys.getenv("CDM5_POSTGRESQL_USER"),
#'   password = Sys.getenv("CDM5_POSTGRESQL_PASSWORD")
#' )
#' # SQL Server
#' connectionDetails <- DatabaseConnector::createDbiConnectionDetails(
#'   dbms = "sql server",
#'   drv = odbc::odbc(),
#'   Driver = "ODBC Driver 18 for SQL Server",
#'   Server = Sys.getenv("CDM5_SQL_SERVER_SERVER"),
#'   Database = Sys.getenv("CDM5_SQL_SERVER_CDM_DATABASE"),
#'   UID = Sys.getenv("CDM5_SQL_SERVER_USER"),
#'   PWD = Sys.getenv("CDM5_SQL_SERVER_PASSWORD"),
#'   TrustServerCertificate = 'yes',
#'   Port = Sys.getenv("DB_PORT")
#' )
#' results <- CdmOnboarding::cdmOnboarding(
#'   connectionDetails = connectionDetails,
#'   cdmSchema = Sys.getenv("CDM_SCHEMA"),
#'   resultsSchema = Sys.getenv("RESULTS_SCHEMA"),
#'   databaseId = Sys.getenv("DATABASE_ID"),
#'   authors = authors,
#'   baseUrl = Sys.getenv("WEBAPI_BASEURL")
#' )
#' unlink("output", recursive = TRUE, force = TRUE)#' 
#' }
#' @export
cdmOnboarding <- function(
  connectionDetails,
  cdmSchema,
  resultsSchema,
  writeSchema = resultsSchema,
  databaseId,
  databaseName,
  databaseDescription,
  authors = "",
  runVocabularyChecks = TRUE,
  runDataTablesChecks = TRUE,
  runPerformanceChecks = TRUE,
  runWebAPIChecks = TRUE,
  runDedChecks = TRUE,
  runDataHashByTable = TRUE,
  smallCellCount = 5,
  baseUrl = NULL,
  outputFolder = "output",
  verboseMode = TRUE,
  dqdJsonPath = NULL,
  optimize = FALSE
) {
  # checkmate::assertClass(connectionDetails, "DbiConnectionDetails")
  checkmate::assertCharacter(databaseId, len = 1, any.missing = FALSE)

  connection <- DatabaseConnector::connect(connectionDetails)

  on.exit({
    if (exists("connection")) {
      DatabaseConnector::disconnect(connection = connection)
      rm(connection)
    }
  })

  # If class dbi, then use @dbiConnection
  isDbiConnection <- inherits(connection, 'DatabaseConnectorDbiConnection')
  if (isDbiConnection) {
    cdm <- CDMConnector::cdmFromCon(
      con = connection@dbiConnection,
      cdmSchema = cdmSchema,
      writeSchema = writeSchema,
      .softValidation = TRUE
    )
  } else {
    ParallelLogger::logWarn("It is recommended to use a DbiConnectionDetails object for the connectionDetails parameter. Using a non-DbiConnectionDetails object may result in errors for benchmarking and drugexposurediagnostics.")
    cdm <- CDMConnector::cdmFromCon(
      con = connection,
      cdmSchema = cdmSchema,
      writeSchema = writeSchema,
      .softValidation = TRUE
    )
  }

  results <- .execute(
    connection = connection,
    cdm = cdm,
    cdmSchema = cdmSchema,
    resultsSchema = resultsSchema,
    writeSchema = writeSchema,
    databaseId = databaseId,
    databaseName = databaseName,
    databaseDescription = databaseDescription,
    runVocabularyChecks = runVocabularyChecks,
    runDataTablesChecks = runDataTablesChecks,
    runPerformanceChecks = runPerformanceChecks,
    runWebAPIChecks = runWebAPIChecks,
    runDedChecks = runDedChecks,
    runDataHashByTable = runDataHashByTable,
    smallCellCount = smallCellCount,
    baseUrl = baseUrl,
    outputFolder = outputFolder,
    verboseMode = verboseMode,
    dqdJsonPath = dqdJsonPath,
    optimize = optimize
  )

  documentGenerated <- NULL

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

  if (runDedChecks) {
    tryCatch({
      exportDedResults(
        results = results,
        outputFolder = outputFolder
      )
    }, error = function(e) {
      ParallelLogger::logError("Could not create DrugExposureDiagnostics csv: ", e)
      ParallelLogger::logInfo("Results from DrugExposureDiagnostics have been saved as an RDS object to the output folder.")
    })
  }

  if (runPerformanceChecks) {
    tryCatch({
      exportPerformanceBenchmark(
        results = results,
        outputFolder = outputFolder
      )
    }, error = function(e) {
      ParallelLogger::logError("Could not create Performance Benchmark csv: ", e)
      ParallelLogger::logInfo("Results from Performance Benchmark have been saved as an RDS object to the output folder.")
    })
  }

  tryCatch({
    bundledResultsLocation <- .bundleResults(outputFolder, databaseId)
    ParallelLogger::logInfo("> All generated CDM Onboarding results are bundled for sharing at: ", bundledResultsLocation)
  }, error = function(e) {
    ParallelLogger::logWarn("> Failed to bundle CDM Onboarding results, no zip bundle has been created: ", e)
  })

  if (!(is.null(documentGenerated) || documentGenerated)) {
    ParallelLogger::logError("CdmOnboarding document generation failed. Please fix any issues or reach out to the DARWIN EU Coordination Centre.") # nolint
  }

  invisible(results)
}

# The main execution of CDM Onboarding analyses (for v5.x)
# Results are returned as list, and stored as an .rds object in the provided output folder
.execute <- function(
  connection,
  cdm,
  cdmSchema,
  resultsSchema,
  writeSchema,
  databaseId,
  databaseName,
  databaseDescription,
  runVocabularyChecks,
  runDataTablesChecks,
  runPerformanceChecks,
  runWebAPIChecks,
  runDedChecks,
  runDataHashByTable,
  smallCellCount,
  baseUrl,
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

  logger <- ParallelLogger::createLogger(
    name = "cdmOnboarding",
    threshold = "INFO",
    appenders = appenders
  )
  ParallelLogger::registerLogger(logger)

  start_time <- Sys.time()
  ParallelLogger::logInfo(sprintf(
    'Running CdmOnboarding v%s %s',
    packageVersion("CdmOnboarding"),
    if (optimize) "(performance optimized)" else ""
  ))

  # CDM Source ------------------------------------------
  cdmSource <- .getCdmSource(connection, cdmSchema, outputFolder)
  if (is.null(cdmSource)) {
    ParallelLogger::logError(sprintf(
      "A populated cdm_source table is required for CdmOnboarding to run. Are your CDM tables in the '%s' schema?",
      cdmSchema
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
  if (missing(databaseName)) {
    databaseName <- cdmSource$CDM_SOURCE_NAME
  }
  if (missing(databaseDescription)) {
    databaseDescription <- cdmSource$SOURCE_DESCRIPTION
  }

  # Check version -----------------------------------
  if (compareVersion(a = cdmVersion, b = "5") < 0) {
    ParallelLogger::logError(sprintf(
      "CdmOnboarding has been developed for OMOP CDM v5 and above. 'v%s' was found in the cdm_source table.",
      cdmVersion
    ))
    stop()
  }

  # If version later than 5.4, check if episode table exists
  if (compareVersion(a = cdmVersion, b = "5.4") >= 0) {
    # Try querying the episode table directly. The function CDMConnector::listTables(connection, cdmSchema) does not always work.
    episodeTableExists <- tryCatch({
      DatabaseConnector::querySql(
        connection, 
        SqlRender::render(
          "SELECT * FROM @cdmDatabaseSchema.episode",
          cdmDatabaseSchema = cdmSchema
        )
      )
      TRUE
    }, error = function(e) {
      FALSE
    })

    if (!episodeTableExists) {
      ParallelLogger::logWarn("CDM version 5.4 specified, but 'episode' table does not exist. Assuming actual version is v5.3") # nolint
      cdmVersion <- "5.3"
    }
  }

  # Snapshot -------------------------
  cdmSnapshot <- tryCatch({
    df <- CDMConnector::snapshot(cdm)
    # computeDataHash in snapshot function requires DatabaseConnector v7.0, while function available since v6.0
    df$cdm_data_hash <- DatabaseConnector::computeDataHash(connection, cdmSchema)
    df
  }, error = function(e) {
    ParallelLogger::logWarn("Could not create snapshot file: ", e)
    NULL
  })

  cdmHashByTable <- NULL
  if (runDataHashByTable) {
    cdmHashByTable <- tryCatch({
      CDMConnector::computeDataHashByTable(cdm)
    }, error = function(e) {
      ParallelLogger::logWarn("Could not create dataHashByTable: ", e)
      NULL
    })
  }

  # Check whether Achilles output is available and get Achilles run info ---------------------------------------
  achillesMetadata <- NULL
  achillesTablesExists <- .checkAchillesTablesExist(connection, resultsSchema)
  achillesMetadata <- .getAchillesMetadata(connection, resultsSchema, outputFolder)
  if (is.null(achillesMetadata) || !achillesTablesExists) {
    ParallelLogger::logError("The output from the Achilles analyses is required.")
    ParallelLogger::logError(sprintf(
      "Please run Achilles first and make sure the resulting Achilles tables are in the given results schema ('%s').",
      resultsSchema
    ))
    return(NULL)
  }
  if (utils::compareVersion(achillesMetadata$ACHILLES_VERSION, '1.7') < 1) {
    ParallelLogger::logWarn(sprintf("Results from an outdated Achilles version (v%s) were detected, please consider installing the latest release of Achilles and rerun CdmOnboarding.", achillesMetadata$ACHILLES_VERSION)) #nolint
  }

  # Check whether results for required Achilles analyses is available. Generate soft warning.
  # At least require person, obs. period, condition and drug exposure. Other domains can be empty.
  expectedAnalysisIds <- c(105, 110, 111, 403, 420, 703, 720)
  analysisIdsAvailable <- .getAvailableAchillesAnalysisIds(connection, resultsSchema, outputFolder)
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
      connection = connection,
      cdmDatabaseSchema = cdmSchema,
      resultsDatabaseSchema = resultsSchema,
      cdmVersion = cdmVersion,
      outputFolder = outputFolder,
      optimize = optimize
    )
  }

  # vocabulary checks ---------------------------------------------------------------------------------------------
  vocabularyResults <- NULL
  if (runVocabularyChecks) {
    ParallelLogger::logInfo("Running Vocabulary Checks")
    vocabularyResults <- vocabularyChecks(
      connection = connection,
      cdmDatabaseSchema = cdmSchema,
      smallCellCount = smallCellCount,
      cdmVersion = cdmVersion,
      outputFolder = outputFolder,
      optimize = optimize
    )
    
    # PHOEBE Concept Recommended exists
    vocabularyResults$countConceptRecommended <- tryCatch({
      if('concept_recommended' %in% names(cdm)) {
        ParallelLogger::logInfo("PHOEBE concept_recommended table is present in the vocabulary.")
        cdm$concept_recommended %>% dplyr::count() %>% dplyr::collect() %>% dplyr::pull()
      } else {
        NA
      }
    }, error = function(e) {
      ParallelLogger::logWarn("Could not retrieve count of concept_recommended: ", e)
      NA
    })
  }

  # performance checks --------------------------------------------------------------------------------------------
  performanceResults <- NULL
  if (runPerformanceChecks) {
    ParallelLogger::logInfo("Running Performance checks")
    performanceResults <- performanceChecks(
      connection = connection,
      cdm = cdm,
      cdmDatabaseSchema = cdmSchema,
      resultsDatabaseSchema = resultsSchema,
      cdmVersion = cdmVersion,
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
      .runDedChecks(cdm)
    }, error = function(e) {
      ParallelLogger::logError("DED checks failed: ", e)
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
    dms = connection@dbms,
    cdmSource = cdmSource,
    cdmSnapshot = cdmSnapshot,
    cdmHashByTable = cdmHashByTable,
    achillesMetadata = achillesMetadata,
    smallCellCount = smallCellCount,
    runWithOptimizedQueries = optimize,
    runWithDbiConnection = inherits(connection, 'DatabaseConnectorDbiConnection'),
    dqdResults = dqdResults,
    drugExposureDiagnostics = drugExposureDiagnostics
  )

  tryCatch({
    outFilePath <- file.path(outputFolder, sprintf("onboarding_results_%s_%s.rds", databaseId, format(Sys.time(), "%Y%m%d")))
    saveRDS(results, outFilePath)
    ParallelLogger::logInfo("> The CDM Onboarding results have been exported to ", outFilePath)
  }, error = function(e) {
    ParallelLogger::logWarn("> Failed to export CDM Onboarding results object, no rds file has been created: ", e)
  })

  return(results)
}

#' Bundles the results in a zip file
#'
#' @description
#' \code{.bundleResults} creates a zip file with results in the outputFolder
#' @param outputFolder  Folder to store the results
#' @param databaseId    ID of your database, this will be used as subfolder for the results.
#' @return The path to the created zip file containing the results
.bundleResults <- function(outputFolder, databaseId) {
  zipName <- file.path(outputFolder, sprintf("Results_Onboarding_%s_%s.zip", databaseId, format(Sys.time(), "%Y%m%d")))
  files <- list.files(outputFolder, "*.*", full.names = TRUE, recursive = TRUE)
  oldWd <- setwd(outputFolder)
  on.exit(setwd(oldWd), add = TRUE)
  DatabaseConnector::createZipFile(zipFile = zipName, files = files)
  return(zipName)
}
