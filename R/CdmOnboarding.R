# @file CdmOnboarding
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
#' @param vocabDatabaseSchema		           String name of database schema that contains OMOP Vocabulary. Default is cdmDatabaseSchema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example 'results.dbo'.
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
#' @param smallCellCount                   To avoid patient identifiability, source values with small counts (<= smallCellCount) are deleted. Set to NULL if you don't want any deletions. (default 5)
#' @param baseUrl                          WebAPI url, example: http://server.org:80/WebAPI
#' @param sqlOnly                          Boolean to determine if Achilles should be fully executed. TRUE = just generate SQL files, don't actually run, FALSE = run Achilles
#' @param outputFolder                     Path to store logs and SQL files
#' @param verboseMode                      Boolean to determine if the console will show all execution steps. Default = TRUE
#' @param dqdJsonPath                      Path to the json of the DQD
#' @param optimize                         Boolean to determine if heuristics will be used to speed up execution. Currently only implemented for postgresql databases. Default = FALSE
#' @param dedIngredientIds                 DEPRECATED, default ingredients are always used (`getDedIngredients()`).
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
cdmOnboarding <- function(connectionDetails,
                          cdmDatabaseSchema,
                          resultsDatabaseSchema,
                          scratchDatabaseSchema = resultsDatabaseSchema,
                          vocabDatabaseSchema = cdmDatabaseSchema,
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
                          smallCellCount = 5,
                          baseUrl = "",
                          sqlOnly = FALSE,
                          outputFolder = "output",
                          verboseMode = TRUE,
                          dqdJsonPath = NULL,
                          optimize = FALSE,
                          dedIngredientIds = NULL) {
  if (missing(databaseId)) {
    stop("Argument databaseId is missing")
  }

  results <- .execute(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    scratchDatabaseSchema = scratchDatabaseSchema,
    vocabDatabaseSchema = vocabDatabaseSchema,
    oracleTempSchema = oracleTempSchema,
    databaseId = databaseId,
    databaseName = databaseName,
    databaseDescription = databaseDescription,
    runVocabularyChecks = runVocabularyChecks,
    runDataTablesChecks = runDataTablesChecks,
    runPerformanceChecks = runPerformanceChecks,
    runWebAPIChecks = runWebAPIChecks,
    runDedChecks = runDedChecks,
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
      },
      error = function(e) {
        ParallelLogger::logError("Could not generate results document: ", e)
        ParallelLogger::logInfo("Results from the checks have been saved as an RDS object to the output folder.")
        FALSE
    })
  }

  tryCatch({
      bundledResultsLocation <- bundleResults(outputFolder, databaseId)
      ParallelLogger::logInfo(sprintf(
        "All generated CDM Onboarding results are bundled for sharing at: %s",
        bundledResultsLocation
      ))
    },
    error = function(e) {
      ParallelLogger::logWarn(sprintf("Failed to bundle CDM Onboarding results, no zip bundle has been created: %s", e))
    }
  )

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
    vocabDatabaseSchema,
    oracleTempSchema,
    databaseId,
    databaseName,
    databaseDescription,
    runVocabularyChecks,
    runDataTablesChecks,
    runPerformanceChecks,
    runWebAPIChecks,
    runDedChecks,
    smallCellCount,
    baseUrl,
    sqlOnly,
    outputFolder,
    verboseMode,
    dqdJsonPath,
    optimize) {
  # Log execution -------------------------------------------------------------------------------------
  ParallelLogger::clearLoggers()
  if (!dir.exists(outputFolder)) {
    dir.create(outputFolder, recursive = TRUE)
  }

  logFileName <- "log_cdmOnboarding.txt"

  if (verboseMode) {
    appenders <- list(ParallelLogger::createConsoleAppender(),
                      ParallelLogger::createFileAppender(layout = ParallelLogger::layoutParallel,
                                                         fileName = file.path(outputFolder, logFileName)))
  } else {
    appenders <- list(ParallelLogger::createFileAppender(layout = ParallelLogger::layoutParallel,
                                                         fileName = file.path(outputFolder, logFileName)))
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
  cdmSource <- .getCdmSource(connectionDetails, cdmDatabaseSchema, sqlOnly, outputFolder)
  if (is.null(cdmSource)) {
    ParallelLogger::logError(sprintf(
      "A populated cdm_source table is required for CdmOnboarding to run. Are your CDM tables in the '%s' schema?",
      cdmDatabaseSchema
    ))
    return(NULL)
  }

  cdmSource$CDM_RELEASE_DATE <- as.character(cdmSource$CDM_RELEASE_DATE)
  cdmSource$SOURCE_RELEASE_DATE <- as.character(cdmSource$SOURCE_RELEASE_DATE)
  cdmVersion <- gsub(pattern = "v", replacement = "", cdmSource$CDM_VERSION)
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
    achillesMetadata <- .getAchillesMetadata(connectionDetails, resultsDatabaseSchema, outputFolder)
    achillesTableExists <- .checkAchillesTablesExist(connectionDetails, resultsDatabaseSchema, outputFolder)
    if (is.null(achillesMetadata) || !achillesTableExists) {
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
      ParallelLogger::logWarn(
          sprintf("Missing Achilles analysis ids in result tables: %s.",
          paste(missingAnalysisIds, collapse = ", "))
      )
      answer <- readline("> If this is expected, press enter to continue. If not, abort (ctrl-c) and rerun Achilles including above analyses.")
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

  ParallelLogger::logInfo(sprintf("CDM Onboarding of database %s started (cdm_version=v%s)", databaseName, cdmVersion))

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
      vocabDatabaseSchema = vocabDatabaseSchema,
      smallCellCount = smallCellCount,
      sqlOnly = sqlOnly,
      outputFolder = outputFolder,
      optimize = optimize
    )
  }

  # performance checks --------------------------------------------------------------------------------------------
  missingPackages <- NULL
  packinfo <- NULL
  hadesPackageVersions <- NULL
  sys_details <- NULL
  dmsVersion <- NULL
  performanceResults <- NULL
  if (runPerformanceChecks) {
    ParallelLogger::logInfo("Check installed R Packages")
    hadesPackages <- getHADESpackages()
    diffPackages <- setdiff(hadesPackages, rownames(installed.packages()))
    missingPackages <- paste(diffPackages, collapse = ', ')

    if (length(diffPackages) > 0) {
      ParallelLogger::logInfo("Not all the HADES packages are installed, see https://ohdsi.github.io/Hades/installingHades.html for more information") # nolint
      ParallelLogger::logInfo(sprintf("Missing: %s", missingPackages))
    } else {
      ParallelLogger::logInfo("> All HADES packages are installed")
    }

    # Note: can have multiple versions of the same package due to renvs
    # Sorting on LibPath to get packages in same environment together
    packinfo <- as.data.frame(installed.packages())
    packinfo <- packinfo[order(packinfo$LibPath, packinfo$Package), c("Package", "Version")]
    hadesPackageVersions <- packinfo[packinfo$Package %in% hadesPackages, ]

    sys_details <- benchmarkme::get_sys_details(sys_info = FALSE)
    ParallelLogger::logInfo(
      sprintf(
        "Running Performance Checks on %s cpu with %s cores, and %s ram.",
        sys_details$cpu$model_name,
        sys_details$cpu$no_of_cores,
        prettyunits::pretty_bytes(as.numeric(sys_details$ram))
      )
    )

    dmsVersion <- .getDbmsVersion(connectionDetails, outputFolder)
    ParallelLogger::logInfo(sprintf('> DBMS version found: "%s"', dmsVersion))

    ParallelLogger::logInfo("Running Performance Checks SQL")
    performanceResults <- performanceChecks(
      connectionDetails = connectionDetails,
      vocabDatabaseSchema = vocabDatabaseSchema,
      resultsDatabaseSchema = resultsDatabaseSchema,
      sqlOnly = sqlOnly,
      outputFolder = outputFolder
    )
  }

  webApiVersion <- "unknown"
  if (runWebAPIChecks && baseUrl != "") {
    ParallelLogger::logInfo("Running WebAPIChecks")

    webApiVersion <- tryCatch({
        version <- ROhdsiWebApi::getWebApiVersion(baseUrl = baseUrl)
        ParallelLogger::logInfo(sprintf("> Connected successfully to '%s'", baseUrl))
        ParallelLogger::logInfo(sprintf("> WebAPI version: %s", version))
        version
      }, error = function(e) {
        ParallelLogger::logError(sprintf("Could not connect to the WebAPI on '%s':\n%s", baseUrl, e))
        return("Failed")
      }
    )
  }

  drugExposureDiagnostics <- NULL
  if (runDedChecks) {
    drugExposureDiagnostics <- .runDedChecks(
      connectionDetails,
      cdmDatabaseSchema
    )
  }

  ParallelLogger::logInfo("Done.")

  ParallelLogger::logInfo(sprintf("Complete CdmOnboarding took %.2f minutes",
    as.numeric(difftime(Sys.time(), start_time), units = "mins")))

  # save results
  results <- list(
    executionDate = format(Sys.time(), "%Y-%m-%d"),
    executionDuration = as.numeric(difftime(Sys.time(), start_time), units = "secs"),
    cdmOnboardingVersion = packageVersion("CdmOnboarding"),
    databaseId = databaseId,
    databaseName = databaseName,
    databaseDescription = databaseDescription,
    vocabularyResults = vocabularyResults,
    dataTablesResults = dataTablesResults,
    packinfo = packinfo,
    hadesPackageVersions = hadesPackageVersions,
    missingPackages = missingPackages,
    performanceResults = performanceResults,
    sys_details = sys_details,
    webAPIversion = webApiVersion,
    cdmSource = cdmSource,
    achillesMetadata = achillesMetadata,
    dms = connectionDetails$dbms,
    dmsVersion = dmsVersion,
    smallCellCount = smallCellCount,
    runWithOptimizedQueries = optimize,
    dqdResults = dqdResults,
    drugExposureDiagnostics = drugExposureDiagnostics
  )

  tryCatch({
      saveRDS(results, file.path(outputFolder, sprintf("onboarding_results_%s_%s.rds", databaseId, format(Sys.time(), "%Y%m%d"))))
      ParallelLogger::logInfo(sprintf("The CDM Onboarding results have been exported to: %s", outputFolder))
    },
    error = function(e) {
      ParallelLogger::logWarn(
        sprintf("Failed to export CDM Onboarding results object, no rds file has been created: %s", e))
    }
  )

  return(results)
}

.getCdmSource <- function(
  connectionDetails,
  cdmDatabaseSchema,
  sqlOnly,
  outputFolder
) {
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = file.path("checks", "get_cdm_source_table.sql"),
                                           packageName = "CdmOnboarding",
                                           dbms = connectionDetails$dbms,
                                           warnOnMissingParameters = FALSE,
                                           cdmDatabaseSchema = cdmDatabaseSchema)
  if (sqlOnly) {
    SqlRender::writeSql(sql = sql, targetFile = file.path(outputFolder, "get_cdm_source_table.sql"))
    return(NULL)
  }
  errorReportFile <- file.path(outputFolder, "cdmSourceError.txt")
  cdmSource <- tryCatch({
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
      cdmSource <- DatabaseConnector::querySql(connection = connection, sql = sql, errorReportFile = errorReportFile)
      if (nrow(cdmSource) > 1) {
        ParallelLogger::logWarn("Multiple records found in the cdm_source table. The first record is used.")
        cdmSource <- cdmSource[1, ]
      }
      if (nrow(cdmSource) == 0) {
        stop("No records found in the cdm_source table. Please populate the table.")
      }
      ParallelLogger::logInfo("> CDM Source table successfully extracted")
      cdmSource
    },
    error = function(e) {
      ParallelLogger::logError(sprintf(
        "> CDM Source table could not be extracted, see %s for more details",
        errorReportFile
      ))
      NULL
    },
    finally = {
      DatabaseConnector::disconnect(connection = connection)
      rm(connection)
    }
  )
  return(cdmSource)
}

required_achilles_tables <- c("achilles_analysis", "achilles_results", "achilles_results_dist")
errorReportFile <- file.path(outputFolder, "errorAchillesExistsSql.txt")
achilles_tables_exist <- tryCatch({
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    for (x in required_achilles_tables) {
        sql <- SqlRender::translate(
        SqlRender::render(
        "SELECT COUNT(*) FROM @resultsDatabaseSchema.@table",
        resultsDatabaseSchema = resultsDatabaseSchema,
        table = x
        ),
        targetDialect = 'postgresql'
        )
    DatabaseConnector::executeSql(
        connection = connection,
        sql = sql,
        progressBar = FALSE,
        reportOverallTime = FALSE,
        errorReportFile = errorReportFile
        )
    }
    TRUE
},
error = function(e) {
    ParallelLogger::logWarn(sprintf("> The Achilles tables have not been found (%s). Please see error report in %s",
    paste(required_achilles_tables, collapse = ', '),
    errorReportFile))
    FALSE
},
finally = {
    DatabaseConnector::disconnect(connection = connection)
    rm(connection)
})
return(achilles_tables_exist)

.getAchillesMetadata <- function(connectionDetails, resultsDatabaseSchema, outputFolder) {
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = file.path("checks", "get_achilles_metadata.sql"),
                                           packageName = "CdmOnboarding",
                                           dbms = connectionDetails$dbms,
                                           warnOnMissingParameters = FALSE,
                                           resultsDatabaseSchema = resultsDatabaseSchema)
  errorReportFile <- file.path(outputFolder, "getAchillesMetadataError.txt")
  achillesMetadata <- tryCatch({
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    achillesMetadata <- DatabaseConnector::querySql(
      connection = connection,
      sql = sql,
      errorReportFile = errorReportFile
    )
    if (nrow(achillesMetadata) > 1) {
      ParallelLogger::logWarn("Multiple records found for same analysis in achilles_results table. The first record is used.") # nolint
      achillesMetadata <- achillesMetadata[1, ]
    } else if (nrow(achillesMetadata) == 0) {
      ParallelLogger::logError("No record for analysis_id 0 found in the achilles_results table. Please run Achilles first.") # nolint
      return(NULL)
    }
    ParallelLogger::logInfo("> Achilles metadata successfully extracted")
    achillesMetadata
  },
  error = function(e) {
    ParallelLogger::logError(sprintf(
      "> Achilles metadata could not be extracted, see %s for more details",
      errorReportFile
    ))
    NULL
  },
  finally = {
    DatabaseConnector::disconnect(connection = connection)
    rm(connection)
  })
  return(achillesMetadata)
}

.processDqdResults <- function(dqdJsonPath) {
  ParallelLogger::logInfo("Reading DataQualityDashboard results")
  tryCatch({
    df <- jsonlite::read_json(path = dqdJsonPath, simplifyVector = TRUE)
    dqdResults <- list(
      version = df$Metadata$DQD_VERSION[1],  # if multiple cdm_source records, then there can be multiple DQD versions
      overview = df$Overview,
      startTimestamp = df$startTimestamp,
      executionTime = df$executionTime
    )
    ParallelLogger::logInfo(sprintf("> Successfully extracted DQD results overview from '%s'", dqdJsonPath))
    }, error = function(e) {
      ParallelLogger::logError(sprintf("Could not process dqdJsonPath '%s'", dqdJsonPath))
    }
  )
  return(dqdResults)
}

.getAvailableAchillesAnalysisIds <- function(connectionDetails, resultsDatabaseSchema) {
    sql <- SqlRender::loadRenderTranslateSql(
        sqlFilename = "getAchillesAnalyses.sql",
        packageName = "DashboardExport",
        dbms = connectionDetails$dbms,
        results_database_schema = resultsDatabaseSchema
    )

    connection <- DatabaseConnector::connect(connectionDetails)
    result <- tryCatch({
            DatabaseConnector::querySql(
                connection = connection,
                sql = sql
            )
        },
        error = function(e) {
            ParallelLogger::logError("Could not get available achilles analyses")
            ParallelLogger::logError(e)
        },
        finally = {
            DatabaseConnector::disconnect(connection = connection)
            rm(connection)
        }
    )
    result$ANALYSIS_ID
}
