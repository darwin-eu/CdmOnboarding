# @file PerformanceChecks.R
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


#' The performane checks (for v5.x)
#'
#' @description
#' \code{PerformanceChecks} runs a list of performance checks as part of the CDM Onboarding procedure
#'
#' @details
#' \code{PerformanceChecks} runs a list of performance checks as part of the CDM Onboarding procedure
#'
#' @param connectionDetails                An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema    	           Fully qualified name of database schema that contains OMOP CDM schema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param resultsDatabaseSchema		         Fully qualified name of database schema that we can write final results to.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_results.dbo'.
#' @param sqlOnly                          Boolean to determine if Achilles should be fully executed. TRUE = just generate SQL files, don't actually run, FALSE = run Achilles
#' @param outputFolder                     Path to store logs and SQL files
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
performanceChecks <- function(connectionDetails,
                              cdmDatabaseSchema,
                              resultsDatabaseSchema,
                              sqlOnly = FALSE,
                              outputFolder = "output") {
  achillesTiming <- executeQuery(outputFolder, "achilles_timing.sql", "Retrieving duration of Achilles queries",
                                 connectionDetails, sqlOnly, resultsDatabaseSchema = resultsDatabaseSchema)

  performanceBenchmark <- executeQuery(outputFolder, "performance_benchmark.sql", "Executing vocabulary query benchmark",
                                       connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema)

  appliedIndexes <- NULL
  if (connectionDetails$dbms == "postgresql") {
    appliedIndexes <- executeQuery(outputFolder, "applied_indexes_postgres.sql", "Retrieving applied indexes",
                                   connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema)
  } else if (connectionDetails$dbms == "sql server") {
    appliedIndexes <- executeQuery(outputFolder, "applied_indexes_sql_server.sql", "Retrieving applied indexes",
                                   connectionDetails, sqlOnly, cdmDatabaseSchema = cdmDatabaseSchema)
  } else {
    ParallelLogger::logWarn(sprintf("The applied indexes query cannot be run for '%s', it is only implemented for PostgreSQL and MS Sql Server.", connectionDetails$dbms))
  }

  list(
    achillesTiming = achillesTiming,
    performanceBenchmark = performanceBenchmark,
    appliedIndexes = appliedIndexes
  )
}

#' Hard coded list of HADES packages that CdmOnboarding checks against.
#' Does NOT update automatically when new HADES packages are released.
#' @return character vector with HADES package names
#' @export
getHADESpackages <- function() {
    ## To update the HADES package list:
    # packageListUrl <- "https://raw.githubusercontent.com/OHDSI/Hades/main/extras/packages.csv" #nolint
    # packageList <- read.table(packageListUrl, sep = ",", header = TRUE) #nolint
    # packages <- packageList$name #nolint
    # dump("packages", "") #nolint
    c(
      "CohortMethod", "SelfControlledCaseSeries", "SelfControlledCohort",
      "EvidenceSynthesis", "PatientLevelPrediction", "DeepPatientLevelPrediction",
      "EnsemblePatientLevelPrediction", "Characterization", "Capr",
      "CirceR", "CohortGenerator", "PhenotypeLibrary", "CohortDiagnostics",
      "PheValuator", "CohortExplorer", "Achilles", "DataQualityDashboard",
      "EmpiricalCalibration", "MethodEvaluation", "Andromeda", "BigKnn",
      "BrokenAdaptiveRidge", "Cyclops", "DatabaseConnector", "Eunomia",
      "FeatureExtraction", "Hydra", "IterativeHardThresholding", "OhdsiSharing",
      "OhdsiShinyModules", "ParallelLogger", "ResultModelManager",
      "ROhdsiWebApi", "ShinyAppBuilder", "SqlRender"
    )
    # cran = c(
    #     "SqlRender", "DatabaseConnector", "DatabaseConnectorJars"
    #  )
}

#' Hard coded list of DARWIN EU® packages that CdmOnboarding checks against.
#' @return character vector with DARWIN EU® package names
#' @export
getDARWINpackages <- function() {
  ## To update the DARWIN package list:
  # packageListUrl <- "https://raw.githubusercontent.com/mvankessel-EMC/DependencyReviewerWhitelists/main/darwin.csv" #nolint
  # packageList <- read.table(packageListUrl, sep = ",", header = TRUE) #nolint
  # packages <- packageList[packageList$version == '*', 'package'] |> #nolint
  #             gsub("darwin-eu-dev/", "", x = _) |> #nolint
  #             gsub("darwin-eu/", "", x = _) |> #nolint
  #             union(c('CdmOnboarding', 'DashboardExport')) #nolint
  # dump("packages", "") #nolint
  c(
    "PatientProfiles", "CDMConnector", "PaRe", "IncidencePrevalence",
    "DrugUtilisation", "DrugExposureDiagnostics", "TreatmentPatterns",
    "CodelistGenerator", "CohortSurvival", "OMOPGenerics", "deckR",
    "ReportGenerator", "CdmOnboarding", "DashboardExport"
  )
  # cran = c(
  #     "CdmConnector", "PaRe",
  #     "DrugUtilisation", "DrugExposureDiagnostics",
  #     "IncidencePrevalence", "PatientProfiles",
  #     "CodelistGenerator"
  #   )
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

  if (cdmVersion == '5.3') {
    return(indexes)
  } else if (cdmVersion == '5.4') {
    # Indexes for the episode and episode event table (note: not applied by default CDM DDL scripts)
    return(
      c(indexes, "idx_episode_person_id_1", "idx_episode_concept_id_1",
      "idx_episode_event_id_1", "idx_ee_field_concept_id_1")
    )
  } else {
    return(indexes)
  }
}

.getDbmsVersion <- function(connectionDetails, outputFolder) {
  versionQuery <- switch(
    connectionDetails$dbms,
    "postgresql" = "SELECT version();",
    "redshift" = "SELECT version();",
    "sql server" = "SELECT @@version;",
    "oracle" = "SELECT * FROM v$version WHERE banner LIKE 'Oracle%';",
    "snowflake" = "SELECT CURRENT_VERSION();",
    "sqlite" = "SELECT SQLITE_VERSION();",
    "ERROR"
  )

  errorReportFile <- file.path(outputFolder, "errorDBMSversion.txt")
  tryCatch({
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
      version <- DatabaseConnector::querySql(
        connection = connection,
        sql = versionQuery,
        errorReportFile = errorReportFile
      )
      # Expect one row, one column
      version[1, 1]
    },
    error = function(e) {
      ParallelLogger::logWarn("> DBMS version could not be retrieved:")
      ParallelLogger::logWarn(e)
      NULL
    },
    finally = {
      DatabaseConnector::disconnect(connection = connection)
      rm(connection)
    }
  )
}
