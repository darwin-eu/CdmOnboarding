# @file CdmOnboarding
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
#' @param vocabDatabaseSchema		           String name of database schema that contains OMOP Vocabulary. Default is cdmDatabaseSchema. On SQL Server, this should specifiy both the database and the schema, so for example 'results.dbo'.
#' @param oracleTempSchema                 For Oracle only: the name of the database schema where you want all temporary tables to be managed. Requires create/insert permissions to this database.
#' @param databaseId                       ID of your database, this will be used as subfolder for the results. If blank, CDM_SOURCE table will be queried to try to obtain this.
#' @param databaseName		                 String name of the database name. If blank, CDM_SOURCE table will be queried to try to obtain this.
#' @param databaseDescription              Provide a short description of the database.
#' @param authors                          List of author names to be added in the document
#' @param runVocabularyChecks              Boolean to determine if vocabulary checks need to be run. Default = TRUE
#' @param runDataTablesChecks              Boolean to determine if table checks need to be run. Default = TRUE
#' @param runWebAPIChecks                  Boolean to determine if WebAPI checks need to be run. Default = TRUE
#' @param runPerformanceChecks             Boolean to determine if performance checks need to be run. Default = TRUE
#' @param smallCellCount                   To avoid patient identifiability, source values with small counts (<= smallCellCount) are deleted. Set to NULL if you don't want any deletions. (default 5)
#' @param baseUrl                          WebAPI url, example: http://server.org:80/WebAPI
#' @param sqlOnly                          Boolean to determine if Achilles should be fully executed. TRUE = just generate SQL files, don't actually run, FALSE = run Achilles
#' @param outputFolder                     Path to store logs and SQL files
#' @param verboseMode                      Boolean to determine if the console will show all execution steps. Default = TRUE
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
cdmOnboarding <- function(connectionDetails,
                          cdmDatabaseSchema,
                          resultsDatabaseSchema = cdmDatabaseSchema,
                          scratchDatabaseSchema = resultsDatabaseSchema,
                          vocabDatabaseSchema = cdmDatabaseSchema,
                          oracleTempSchema = resultsDatabaseSchema,
                          databaseId = "",
                          databaseName = "",
                          databaseDescription = "",
                          authors = "",
                          runVocabularyChecks = TRUE,
                          runDataTablesChecks = TRUE,
                          runPerformanceChecks = TRUE,
                          runWebAPIChecks = TRUE,
                          smallCellCount = 5,
                          baseUrl = "",
                          sqlOnly = FALSE,
                          outputFolder = "output",
                          verboseMode = TRUE) {
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
    smallCellCount = smallCellCount,
    baseUrl = baseUrl,
    sqlOnly = sqlOnly,
    outputFolder = outputFolder,
    verboseMode = verboseMode
  )

  if(is.null(results)) {
    return(NULL)
  }

  documentGenerationError <- FALSE
  if (!sqlOnly) {
    tryCatch({
      generateResultsDocument(
        results = results,
        outputFolder = outputFolder
      )},
      error = function (e) {
        ParallelLogger::logError("Could not generate results document: ", e)
        ParallelLogger::logInfo("Results from the checks have been saved as an RDS object to the output folder.")
        documentGenerationError <- TRUE
    })
  }

  tryCatch({
      bundledResultsLocation <- bundleResults(outputFolder, databaseId)
      ParallelLogger::logInfo(sprintf("All generated CDM Onboarding results are bundled for sharing at: %s", bundledResultsLocation))
    },
    error = function (e) {
      ParallelLogger::logWarn(sprintf("Failed to bundle CDM Onboarding results, no zip bundle has been created: %s", e))
    }
  )

  if (documentGenerationError) {
    logError("!! CdmOnboarding document generation failed. Please fix any issues or reach out to the DARWIN-EU Coordination Centre.")
  }

  return(results)
}

#' The main CDM Onboarding analyses (for v5.x)
#'
#' @description
#' \code{cdmOnboarding} runs a list of checks as part of the CDM Onboarding procedure
#'
#' @details
#' \code{cdmOnboarding} runs a list of checks as part of the CDM Onboarding procedure
#' Results are returned and stored as an .rds object.
.execute <- function (
    connectionDetails,
    cdmDatabaseSchema,
    resultsDatabaseSchema = cdmDatabaseSchema,
    scratchDatabaseSchema = resultsDatabaseSchema,
    vocabDatabaseSchema = cdmDatabaseSchema,
    oracleTempSchema = resultsDatabaseSchema,
    databaseId,
    databaseName,
    databaseDescription,
    runVocabularyChecks,
    runDataTablesChecks,
    runPerformanceChecks,
    runWebAPIChecks,
    smallCellCount,
    baseUrl,
    sqlOnly,
    outputFolder,
    verboseMode) {
  # Log execution -----------------------------------------------------------------------------------------------------------------
  ParallelLogger::clearLoggers()
  if(!dir.exists(outputFolder)){dir.create(outputFolder,recursive=T)}

  logFileName <-"log_cdmOnboarding.txt"

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

  # CDM Source ------------------------------------------
  cdmSource <- .getCdmSource(connectionDetails, cdmDatabaseSchema, sqlOnly, outputFolder)
  if (is.null(cdmSource)) {
    ParallelLogger::logError("A populated cdm_source table is required for CdmOnboarding to run.")
    return(NULL)
  }
  cdmSource$CDM_VERSION <- as.character(cdmSource$CDM_VERSION)
  cdmSource$CDM_RELEASE_DATE <- as.character(cdmSource$CDM_RELEASE_DATE)
  cdmSource$SOURCE_RELEASE_DATE <- as.character(cdmSource$SOURCE_RELEASE_DATE)

  # Get source name and id from cdm_source if none provided ----------------------------------------------------------------------------------------------
  if (missing(databaseId) & !sqlOnly) {
    databaseId <- cdmSource$CDM_SOURCE_ABBREVIATION
  }
  if (missing(databaseName) & !sqlOnly) {
    databaseName <- cdmSource$CDM_SOURCE_NAME
  }

  # Check version -----------------------------------
  if (compareVersion(a = gsub(pattern = "v", replacement = "", cdmSource$CDM_VERSION), b = "5") < 0) {
    ParallelLogger::logError("Not possible to execute the check, this function is only for v5 and above. '", cdmSource$CDM_VERSION, "' was found in the cdm_source table.")
    return(NULL)
  }

  # Check whether Achilles output is available ---------------------------------------
  if (!sqlOnly && !.checkAchillesTablesExist(connectionDetails, resultsDatabaseSchema)) {
    ParallelLogger::logError(paste0("The output from the Achilles analyses is required.\nPlease run Achilles first and make sure the resulting Achilles tables are in the given results schema ('", resultsDatabaseSchema, "')."))
    return(NULL)
  }

  # Establish folder paths --------------------------------------------------------------------------------------------------------
  if (!dir.exists(outputFolder)) {
    dir.create(path = outputFolder, recursive = TRUE)
  }

  ParallelLogger::logInfo(paste0("CDM Onboarding of database ", databaseName, " started (cdm_version=",cdmSource$CDM_VERSION,")"))

  # data table checks ------------------------------------------------------------------------------------------------------------
  dataTablesResults <- NULL
  if (runDataTablesChecks) {
    ParallelLogger::logInfo(paste0("Running Data Table Checks"))
    dataTablesResults <- dataTablesChecks(connectionDetails = connectionDetails,
                                  cdmDatabaseSchema = cdmDatabaseSchema,
                                  resultsDatabaseSchema = resultsDatabaseSchema,
                                  cdmVersion = cdmSource$CDM_VERSION,
                                  outputFolder = outputFolder,
                                  sqlOnly = sqlOnly)
  }

  # vocabulary checks ------------------------------------------------------------------------------------------------------------
  vocabularyResults <- NULL
  if (runVocabularyChecks) {
    ParallelLogger::logInfo(paste0("Running Vocabulary Checks"))
    vocabularyResults<-vocabularyChecks(connectionDetails = connectionDetails,
                     cdmDatabaseSchema = cdmDatabaseSchema,
                     vocabDatabaseSchema = vocabDatabaseSchema,
                     resultsDatabaseSchema = resultsDatabaseSchema,
                     smallCellCount = smallCellCount,
                     oracleTempSchema = oracleTempSchema,
                     sqlOnly = sqlOnly,
                     outputFolder = outputFolder)
  }

  # performance checks ------------------------------------------------------------------------------------------------------------
  packinfo <- NULL
  sys_details <- NULL
  hadesPackageVersions <- NULL
  performanceResults <- NULL
  missingPackages <- NULL
  if (runPerformanceChecks) {
    ParallelLogger::logInfo(paste0("Check installed R Packages"))
    packages <- c("SqlRender", "DatabaseConnector", "DatabaseConnectorJars", "PatientLevelPrediction", "CohortDiagnostics", "CohortMethod", "Cyclops","ParallelLogger","FeatureExtraction","Andromeda",
                  "ROhdsiWebApi","OhdsiSharing","Hydra","Eunomia","EmpiricalCalibration","MethodEvaluation","EvidenceSynthesis","SelfControlledCaseSeries","SelfControlledCohort")
    diffPackages <- setdiff(packages, rownames(installed.packages()))
    missingPackages <- paste(diffPackages, collapse=', ')

    if (length(diffPackages)>0){
      ParallelLogger::logInfo(paste0("Not all the HADES packages are installed, see https://ohdsi.github.io/Hades/installingHades.html for more information"))
      ParallelLogger::logInfo(paste0("Missing:", missingPackages))
    } else {
      ParallelLogger::logInfo(paste0("> All HADES packages are installed"))
    }

    packinfo <- installed.packages(fields = c("Package", "Version"))
    hades<-packinfo[,c("Package", "Version")]
    hadesPackageVersions <- as.data.frame(hades[row.names(hades) %in% packages,])

    sys_details <- benchmarkme::get_sys_details(sys_info=FALSE)
    ParallelLogger::logInfo(paste0("Running Performance Checks on ", sys_details$cpu$model_name, " cpu with ", sys_details$cpu$no_of_cores, " cores, and ", prettyunits::pretty_bytes(as.numeric(sys_details$ram)), " ram."))

    ParallelLogger::logInfo(paste0("Running Performance Checks SQL"))
    performanceResults <- performanceChecks(connectionDetails = connectionDetails,
                      cdmDatabaseSchema = cdmDatabaseSchema,
                      resultsDatabaseSchema = resultsDatabaseSchema,
                      oracleTempSchema = oracleTempSchema,
                      sqlOnly = sqlOnly,
                      outputFolder = outputFolder)
  }

  webAPIversion <- "unknown"
  if (runWebAPIChecks && baseUrl != ""){
    ParallelLogger::logInfo(paste0("Running WebAPIChecks"))

    tryCatch({
      webAPIversion <- ROhdsiWebApi::getWebApiVersion(baseUrl = baseUrl)
      ParallelLogger::logInfo(sprintf("> Connected successfully to %s", baseUrl))
      ParallelLogger::logInfo(sprintf("> WebAPI version: %s", webAPIversion))},
             error = function (e) {
               ParallelLogger::logError(paste0("Could not connect to the WebAPI: ", baseUrl))
               webAPIversion <- "Failed"
      })
  }

  ParallelLogger::logInfo(paste0("Done."))

  duration <- as.numeric(difftime(Sys.time(),start_time), units="mins")
  ParallelLogger::logInfo(paste("Complete CdmOnboarding took ", sprintf("%.2f", duration)," minutes"))

  # save results  ------------------------------------------------------------------------------------------------------------
  results<-list(executionDate = date(),
                executionDuration = as.numeric(difftime(Sys.time(),start_time), units="secs"),
                databaseName = databaseName,
                databaseId = databaseId,
                databaseDescription = databaseDescription,
                vocabularyResults = vocabularyResults,
                dataTablesResults = dataTablesResults,
                packinfo=packinfo,
                hadesPackageVersions = hadesPackageVersions,
                missingPackages = missingPackages,
                performanceResults = performanceResults,
                sys_details= sys_details,
                webAPIversion = webAPIversion,
                cdmSource = cdmSource,
                dms=connectionDetails$dbms,
                smallCellCount=smallCellCount)

  tryCatch({
      saveRDS(results, file.path(outputFolder, sprintf("onboarding_results_%s.rds", databaseId)))
      ParallelLogger::logInfo(sprintf("The CDM Onboarding results have been exported to: %s", outputFolder))
    },
    error = function (e) {
      ParallelLogger::logWarn(sprintf("Failed to export CDM Onboarding results object, no rds file has been created: %s", e))
    }
  )

  return(results)
}

.getCdmSource <- function(connectionDetails,
                           cdmDatabaseSchema,sqlOnly,outputFolder) {
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = file.path("checks","get_cdm_source_table.sql"),
                                           packageName = "CdmOnboarding",
                                           dbms = connectionDetails$dbms,
                                           warnOnMissingParameters = FALSE,
                                           cdmDatabaseSchema = cdmDatabaseSchema)
  if (sqlOnly) {
    SqlRender::writeSql(sql = sql, targetFile = file.path(outputFolder, "get_cdm_source_table.sql"))
    return(NULL)
  }

  cdmSource <- tryCatch({
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
      cdmSource <- DatabaseConnector::querySql(connection = connection, sql = sql, errorReportFile = file.path(outputFolder, "cdmSourceError.txt"))
      if (nrow(cdmSource) > 1) {
        ParallelLogger::logWarn("Multiple records found in the cdm_source table. The first record is used.")
        cdmSource <- cdmSource[1,]
      }
      if (nrow(cdmSource) == 0) {
        stop("No records found in the cdm_source table. Please populate the table.")
      }
      ParallelLogger::logInfo("> CDM Source table successfully extracted")
      cdmSource
    },
    error = function (e) {
      ParallelLogger::logError(paste0("> CDM Source table could not be extracted, see ", file.path(outputFolder,"cdmSourceError.txt"), " for more details"))
      NULL
    },
    finally = {
      DatabaseConnector::disconnect(connection = connection)
      rm(connection)
    }
  )
  return(cdmSource)
}

.checkAchillesTablesExist <- function(connectionDetails, resultsDatabaseSchema) {
  required_achilles_tables <- c("achilles_analysis", "achilles_results", "achilles_results_dist")
  achilles_tables_exist <- tryCatch({
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    for(x in required_achilles_tables) {
      sql <- SqlRender::translate(
               SqlRender::render(
                 "SELECT COUNT(*) FROM @resultsDatabaseSchema.@table",
                 resultsDatabaseSchema=resultsDatabaseSchema,
                 table=x
               ),
               targetDialect = 'postgresql'
             )
      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql,
        progressBar = F,
        reportOverallTime = F,
        errorReportFile = "errorAchillesExistsSql.txt"
      )
    }
    TRUE
  },
  error = function (e) {
    ParallelLogger::logWarn("The Achilles tables have not been found (", required_achilles_tables, "). Please see error report in errorAchillesExistsSql.txt")
    FALSE
  },
  finally = {
    DatabaseConnector::disconnect(connection = connection)
    rm(connection)
  })
  return(achilles_tables_exist)
}
