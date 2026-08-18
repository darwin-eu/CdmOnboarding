# @file PerformanceChecks.R
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


#' The performane checks (for v5.x)
#'
#' @description
#' \code{PerformanceChecks} runs a list of performance checks as part of the CDM Onboarding procedure
#'
#' @details
#' \code{PerformanceChecks} runs a list of performance checks as part of the CDM Onboarding procedure
#'
#' @param connection                       An R object of type \code{DatabaseConnectorDbiConnection}
#' @param cdm                              An R object of type \code{cdm_reference}
#' @param cdmDatabaseSchema    	           Fully qualified name of database schema that contains OMOP CDM schema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param resultsDatabaseSchema		         Fully qualified name of database schema that we can write final results to.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_results.dbo'.
#' @param cdmVersion                       Version of the CDM to check against. Default is "5.4".
#' @param outputFolder                     Path to store logs and SQL files
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
performanceChecks <- function(
  connection,
  cdm,
  cdmDatabaseSchema,
  resultsDatabaseSchema,
  cdmVersion = "5.4",
  outputFolder = "output"
) {
  achillesTiming <- executeQuery(
    outputFolder,
    "achilles_timing.sql",
    successMessage = "Retrieving duration of Achilles queries",
    connection = connection,
    resultsDatabaseSchema = resultsDatabaseSchema
  )

  # System details
  systemDetails <- list(
    r_version = version,
    cpu = tryCatch(benchmarkme::get_cpu(), error = function(e) list(vendor_id = NA, model_name = NA, no_of_cores = NA)),
    ram = tryCatch(benchmarkme::get_ram(), error = function(e) NA)
  )

  ParallelLogger::logInfo(sprintf(
    "Running Performance Checks on %s cpu with %s cores, and %s ram.",
    systemDetails$cpu$model_name,
    systemDetails$cpu$no_of_cores,
    prettyunits::pretty_bytes(as.numeric(systemDetails$ram))
  ))

  performanceBenchmark <- executeQuery(
    outputFolder,
    "performance_benchmark.sql",
    successMessage = "Executing vocabulary query benchmark",
    connection = connection,
    cdmDatabaseSchema = cdmDatabaseSchema
  )

  cdmConnectorBenchmark <- tryCatch({
    .runBenchmarkCdmConnector(cdm)
  }, error = function(e) {
    ParallelLogger::logError("Execution of CDMConnector Benchmark failed: ", e)
    NULL
  })

  # Cohort Benchmark checks -------------------------------------------------------------------------------------
  cohortBenchmark <- tryCatch({
    .runCohortBenchmark(cdm)
  }, error = function(e) {
    ParallelLogger::logError("Cohort Benchmark failed: ", e)
    NULL
  })

  analyticsBenchmark <- tryCatch({
    .analyticsBenchmarks(cdm)
  }, error = function(e) {
    ParallelLogger::logError("Execution of Analytics Benchmarks failed: ", e)
    NULL
  })

  # Applied indexes
  ParallelLogger::logInfo("> Extracting applied indexes")
  appliedIndexes <- NULL
  if (connection@dbms == "postgresql") {
    appliedIndexes <- executeQuery(
      outputFolder,
      "applied_indexes_postgres.sql",
      successMessage = "Retrieving applied indexes",
      connection = connection,
      cdmDatabaseSchema = cdmDatabaseSchema
    )
  } else if (connection@dbms == "sql server") {
    appliedIndexes <- executeQuery(
      outputFolder,
      "applied_indexes_sql_server.sql",
      successMessage = "Retrieving applied indexes",
      connection = connection,
      cdmDatabaseSchema = cdmDatabaseSchema
    )
  } else {
    ParallelLogger::logWarn(sprintf("The applied indexes query cannot be run for '%s', it is only implemented for PostgreSQL and MS Sql Server.", connection@dbms))
  }

  # Installed Packages
  ParallelLogger::logInfo("> Retrieving HADES and DARWIN package versions")
  hadesPackages <- .getHADESpackages()
  hadesPackageVersions <- .getPackacheVersions(hadesPackages)

  darwinPackages <- .getDARWINpackages()
  darwinPackageVersions <- .getPackacheVersions(darwinPackages)

  # DBMS version
  dmsVersion <- .getDbmsVersion(connection, outputFolder)
  ParallelLogger::logInfo(sprintf('> DBMS version found: "%s"', dmsVersion))

  list(
    achillesTiming = achillesTiming,
    performanceBenchmark = performanceBenchmark,
    cdmConnectorBenchmark = cdmConnectorBenchmark,
    cohortBenchmark = cohortBenchmark,
    analyticsBenchmark = analyticsBenchmark,
    appliedIndexes = appliedIndexes,
    systemDetails = systemDetails,
    dmsVersion = dmsVersion,
    hadesPackageVersions = hadesPackageVersions,
    darwinPackageVersions = darwinPackageVersions
  )
}

#' Hard coded list of HADES packages that CdmOnboarding checks against.
#' Does NOT update automatically when new HADES packages are released.
#' @return character vector with HADES package names
.getHADESpackages <- function() {
  ## To update the HADES package list:
  # packageListUrl <- "https://raw.githubusercontent.com/OHDSI/Hades/main/extras/packages.csv" #nolint
  # packageList <- read.table(packageListUrl, sep = ",", header = TRUE) #nolint
  # packages <- packageList$name #nolint
  # dump("packages", "") #nolint
  c(
    "CohortMethod", "SelfControlledCaseSeries", "SelfControlledCohort", 
    "EvidenceSynthesis", "PatientLevelPrediction", "DeepPatientLevelPrediction", 
    "EnsemblePatientLevelPrediction", "Characterization", "CohortIncidence", 
    "TreatmentPatterns", "Capr", "CirceR", "CohortGenerator", "PhenotypeLibrary", 
    "CohortDiagnostics", "PheValuator", "CohortExplorer", "Keeper", 
    "Achilles", "DataQualityDashboard", "EmpiricalCalibration", "MethodEvaluation", 
    "Andromeda", "BigKnn", "BrokenAdaptiveRidge", "Cyclops", "DatabaseConnector", 
    "Eunomia", "FeatureExtraction", "IterativeHardThresholding", 
    "OhdsiSharing", "OhdsiShinyModules", "ParallelLogger", "ResultModelManager", 
    "ROhdsiWebApi", "OhdsiShinyAppBuilder", "Strategus", "SqlRender", 
    "OhdsiReportGenerator", "Hydra", "ShinyAppBuilder"
  )
}

#' Returns data frame of Version, LibPath and URL.
#' More efficient than using packInfo, as it only retrieves info for the packages specified.
#' @param packageNames character vector of package names to retrieve version information for.
#' @return data frame with columns Package, Version, LibPath and URL.
.getPackacheVersions <- function(packageNames) {
  result <- c()
  for (pkg in packageNames) {
    p <- suppressWarnings(packageDescription(pkg, fields = c("Package", "Version", "URL")))
    if(length(p) > 1) {
      p['LibPath'] <- find.package('DataQualityDashboard')
      result <- rbind(
        result,
        unlist(p[c("Package", "Version", "LibPath", "URL")])
      )
    } 
  }
  return(data.frame(result))
}

#' Hard coded list of DARWIN EU® packages that CdmOnboarding checks against.
#' @return character vector with DARWIN EU® package names
.getDARWINpackages <- function() {
  ## To update the DARWIN package list:
  # packageListUrl <- "https://raw.githubusercontent.com/darwin-eu-dev/PackagesStatusPage/refs/heads/main/app/packages.csv" #nolint
  # packageList <- read.table(packageListUrl, sep = ",", header = TRUE) #nolint
  # packages <- packageList |> dplyr::select(name) |> unique() |> unlist() |> as.character()
  # dump("packages", "") #nolint
  c(
    "PatientProfiles", "CohortCharacteristics", "IncidencePrevalence", 
    "TreatmentPatterns", "DrugUtilisation", "CohortSurvival", "omopgenerics", 
    "PaRe", "CDMConnector", "CodelistGenerator", "DashboardExport", 
    "visOmopResults", "DrugExposureDiagnostics", "CdmOnboarding", 
    "ReportGenerator", "DarwinShinyModules"
  )
}

.getExpectedIndexes <- function(cdmVersion) {
  cdmVersion <- sub(pattern = "v", replacement = "", cdmVersion)

  # Default indexes for an OMOP CDM. Note that currently these are the same for both v5.3 and v5.4.
  # Extracted idx from https://github.com/OHDSI/CommonDataModel/blob/main/inst/sql/sql_server/OMOP_CDM_indices_v5.4.sql
  # and xpk from https://github.com/OHDSI/CommonDataModel/blob/main/inst/ddl/5.4/postgresql/OMOPCDM_postgresql_5.4_primary_keys.sql
  indexes <- c(
    "xpk_person", "xpk_observation_period", "xpk_visit_occurrence", "xpk_visit_detail",
    "xpk_condition_occurrence", "xpk_drug_exposure", "xpk_procedure_occurrence",
    "xpk_device_exposure", "xpk_measurement", "xpk_observation",
    "xpk_note", "xpk_note_nlp", "xpk_specimen", "xpk_location", "xpk_care_site",
    "xpk_provider", "xpk_payer_plan_period", "xpk_cost", "xpk_drug_era",
    "xpk_dose_era", "xpk_condition_era", "xpk_episode", "xpk_metadata",
    "xpk_concept", "xpk_vocabulary", "xpk_domain", "xpk_concept_class", "xpk_relationship",
    "idx_person_id", "idx_gender", "idx_observation_period_id_1",
    "idx_visit_person_id_1", "idx_visit_concept_id_1", "idx_visit_det_person_id_1",
    "idx_visit_det_concept_id_1", "idx_visit_det_occ_id", "idx_condition_person_id_1",
    "idx_condition_concept_id_1", "idx_condition_visit_id_1", "idx_drug_person_id_1",
    "idx_drug_concept_id_1", "idx_drug_visit_id_1", "idx_procedure_person_id_1",
    "idx_procedure_concept_id_1", "idx_procedure_visit_id_1", "idx_device_person_id_1",
    "idx_device_concept_id_1", "idx_device_visit_id_1", "idx_measurement_person_id_1",
    "idx_measurement_concept_id_1", "idx_measurement_visit_id_1",
    "idx_observation_person_id_1", "idx_observation_concept_id_1",
    "idx_observation_visit_id_1", "idx_death_person_id_1", "idx_note_person_id_1",
    "idx_note_concept_id_1", "idx_note_visit_id_1", "idx_note_nlp_note_id_1",
    "idx_note_nlp_concept_id_1", "idx_specimen_person_id_1", "idx_specimen_concept_id_1",
    "idx_fact_relationship_id1", "idx_fact_relationship_id2", "idx_fact_relationship_id3",
    "idx_location_id_1", "idx_care_site_id_1", "idx_provider_id_1",
    "idx_period_person_id_1", "idx_cost_event_id", "idx_drug_era_person_id_1",
    "idx_drug_era_concept_id_1", "idx_dose_era_person_id_1", "idx_dose_era_concept_id_1",
    "idx_condition_era_person_id_1", "idx_condition_era_concept_id_1",
    "idx_metadata_concept_id_1", "idx_concept_concept_id", "idx_concept_code",
    "idx_concept_vocabluary_id", "idx_concept_domain_id", "idx_concept_class_id",
    "idx_vocabulary_vocabulary_id", "idx_domain_domain_id", "idx_concept_class_class_id",
    "idx_concept_relationship_id_1", "idx_concept_relationship_id_2",
    "idx_concept_relationship_id_3", "idx_relationship_rel_id", "idx_concept_synonym_id",
    "idx_concept_ancestor_id_1", "idx_concept_ancestor_id_2", "idx_source_to_concept_map_3",
    "idx_source_to_concept_map_1", "idx_source_to_concept_map_2",
    "idx_source_to_concept_map_c", "idx_drug_strength_id_1", "idx_drug_strength_id_2"
  )

  tables <- c(
    "person", "observation_period", "visit_occurrence", "visit_detail", 
    "condition_occurrence", "drug_exposure", "procedure_occurrence", 
    "device_exposure", "measurement", "observation", "note", "note_nlp", 
    "specimen", "location", "care_site", "provider", "payer_plan_period", 
    "cost", "drug_era", "dose_era", "condition_era", "episode", "metadata", 
    "concept", "vocabulary", "domain", "concept_class", "relationship", 
    "person", "person", "observation_period", "visit_occurrence", 
    "visit_occurrence", "visit_detail", "visit_detail", 
    "visit_detail", "condition_occurrence", "condition_occurrence", 
    "condition_occurrence", "drug_exposure", "drug_exposure", "drug_exposure", 
    "procedure_occurrence", "procedure_occurrence", "procedure_occurrence", 
    "device_exposure", "device_exposure", "device_exposure", "measurement", 
    "measurement", "measurement", "observation", "observation", "observation", "death", 
    "note", "note", "note", "note", "note", "specimen", "specimen", 
    "fact_relationship", "fact_relationship", "fact_relationship", 
    "location", "care_site", "provider", "payer_plan_period", 
    "cost_event", "drug_era", "drug_era", "dose_era", "dose_era", "condition_era", 
    "condition_era", "metadata", "concept", "concept", "concept", "concept", 
    "concept", "vocabulary", "domain", "concept_class", "concept_relationship", "concept_relationship", 
    "concept_relationship", "relationship", "concept_synonym", 
    "concept_ancestor", "concept_ancestor", "source_to_concept_map", 
    "source_to_concept_map", "source_to_concept_map", "source_to_concept_map", 
    "drug_strength", "drug_strength"
  )

  if (cdmVersion == '5.4') {
    # Indexes for the episode and episode event table (note: not applied by default CDM DDL scripts)
    indexes <- c(indexes, "idx_episode_person_id_1", "idx_episode_concept_id_1",
                 "idx_episode_event_id_1", "idx_ee_field_concept_id_1")
    tables <- c(tables, "episode", "episode", "episode_event", "episode_event")
  }

  data.frame(
    TABLENAME = tables,
    INDEXNAME = indexes,
    type = substr(indexes, 1, 3)
  )
}

.getDbmsVersion <- function(connection, outputFolder) {
  versionQuery <- switch(
    connection@dbms,
    "postgresql" = "SELECT version();",
    "redshift" = "SELECT version();",
    "sql server" = "SELECT @@version;",
    "oracle" = "SELECT * FROM v$version WHERE banner LIKE 'Oracle%';",
    "snowflake" = "SELECT CURRENT_VERSION();",
    "sqlite" = "SELECT SQLITE_VERSION();",
    "spark" = "SELECT version();",
    "duckdb" = "SELECT version();",
    NULL
  )

  if (is.null(versionQuery)) {
    ParallelLogger::logWarn(sprintf("> DBMS '%s' is not supported for version retrieval.", connection@dbms))
    return(NULL)
  }

  errorReportFile <- file.path(outputFolder, "errorDBMSversion.txt")
  tryCatch({
    version <- DatabaseConnector::querySql(
      connection = connection,
      sql = versionQuery,
      errorReportFile = errorReportFile
    )
    # Expect one row, one column
    version[1, 1]
  }, error = function(e) {
    ParallelLogger::logWarn("> DBMS version could not be retrieved:")
    ParallelLogger::logWarn(e)
    NULL
  })
}

#' @import httr
.getWebApiVersion <- function(baseUrl) {
  if (grepl("/$", baseUrl)) {
    baseUrl <- sub("/$", "", baseUrl)
  }
  url <- paste0(baseUrl, "/info")

  response <- httr::GET(url)
  if (response$status %in% c(200)) {
    content <- httr::content(response)
    return(content$version)
  }
  return(NULL)
}
