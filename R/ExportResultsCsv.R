# @file ExportDedResults.R
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
# @author Maxim Moinat

#' Export DrugExposureDiagnostics results to csv file in same folder as input file path
#'
#' @param path path to the CdmOnboarding .rds results file, output is written to the same folder
#' @return Writes to path a csv file with the DrugExposureDiagnostics summary results
#' @export
exportDedResultsFromPath <- function(
  path
) {
  results <- readRDS(path)
  outputFolder <- dirname(path)
  exportDedResults(results, outputFolder)
}

#' Export DrugExposureDiagnostics results to csv file
#'
#' @param results results object from \code{cdmOnboarding}
#' @param df_ded optional dataframe with ded results, if NULL will use results$drugExposureDiagnostics
#' @param outputFolder folder to store the results
#' @return Writes to outputFolder a csv file with the DrugExposureDiagnostics summary results
#' @export
exportDedResults <- function(
  results,
  df_ded = NULL,
  outputFolder = getwd()
) {
  if (is.null(df_ded)) {
    df_ded <- results$drugExposureDiagnostics
  }

  if (is.null(df_ded$result) || nrow(df_ded$result) == 0) {
    ParallelLogger::logInfo("No DrugExposureDiagnostics results to export")
    return()
  }
  dedVersion <- .getDedVersion(df_ded)

  dedResult <- .formatDedResults(df_ded$result, dedVersion)

  outputFilename <- sprintf('ded_results_%s_%s.csv', results$databaseId, format(Sys.time(), "%Y%m%d"))

  metadata <- c(
      sprintf("Execution Date: %s", results$executionDate),
      sprintf("Source Release Date: %s", results$cdmSource$SOURCE_RELEASE_DATE),
      sprintf("CDM Release Date: %s", results$cdmSource$CDM_RELEASE_DATE),
      sprintf("DED Version: %s", dedVersion),
      sprintf("Execution Duration: %.1f s", df_ded$duration)
  )
  metadata <- setNames(c(metadata, rep(NA, ncol(dedResult) - length(metadata))), names(dedResult))

  dedResult %>%
    # Numeric into character to be able to add metadata rows
    mutate(
      `#Records` = as.character(.data$`#Records`),
      `#Persons` = as.character(.data$`#Persons`),
    ) %>%
    # add metadata
    rbind(metadata) %>%
    write.csv(
      file = file.path(outputFolder, outputFilename),
      row.names = TRUE # first column will be removed when uploading to portal
    )
  ParallelLogger::logInfo(sprintf("> DrugExposureDiagnostics results written to '%s'", file.path(outputFolder, outputFilename)))
}

.formatDedResults <- function(ded_results, dedVersion) {
  ded_results <- ded_results %>%
    # Ingredients with highest record count first
    arrange(desc(.data$n_records)) %>%
    # Format counts with thousands separator and round to nearest 10, and convert concept id to character to prevent scientific notation
    mutate(
      ingredient_concept_id = as.character(.data$ingredient_concept_id),
      # Round counts to nearest 10
      n_records = prettyHr(round(.data$n_records / 10) * 10),
      n_patients = prettyHr(round(.data$n_patients / 10) * 10)   
    )

  # In DED v1.0.9 the dose columns can be missing
  if (!("n_dose_and_missingness" %in% colnames(ded_results))) {
    ded_results$n_dose_and_missingness <- NA
  }

  if (!("median_daily_dose_q05_q95" %in% colnames(ded_results))) {
    ded_results$median_daily_dose_q05_q95 <- NA
  }

  if (dedVersion >= '1.0.5') {
    ded_results <- ded_results %>%
      select(
        `Ingredient` = .data$ingredient,
        `#Records` = .data$n_records,
        `#Persons` = .data$n_patients,
        `Type` = .data$proportion_of_records_by_drug_type,
        `Route` = .data$proportion_of_records_by_route_type,
        `Dose Form present` = .data$proportion_of_records_with_dose_form,
        `Missingness [quantity, start, end, days_supply]` = .data$missing_quantity_exp_start_end_days_supply,
        `Dose availability` = .data$n_dose_and_missingness,
        `Dose distrib.` = .data$median_daily_dose_q05_q95,
        `Quantity distrib.` = .data$median_quantity_q05_q95,
        `Exposure days distrib.` = .data$median_drug_exposure_days_q05_q95,
        `Neg. Days` = .data$proportion_of_records_with_negative_drug_exposure_days
      )
  } else {
    ded_results <- ded_results %>%
      select(
        `Ingredient` = .data$ingredient,
        `Concept ID` = .data$ingredient_concept_id,
        `#Records` = .data$n_records,
        `#Persons` = .data$n_patients,
        `Type (n,%)` = .data$proportion_of_records_by_drug_type,
        `Route (n,%)` = .data$proportion_of_records_by_route_type,
        `Dose Form present n (%)` = .data$proportion_of_records_with_dose_form,
        `Fixed amount dose form n (%)` = .data$proportion_of_records_missing_denominator_unit_concept_id,
        `Amount distrib. [null or missing]` = .data$median_amount_value_q05_q95,
        `Quantity distrib. [null or missing]` = .data$median_quantity_q05_q95,
        `Exposure days distrib. [null or missing]` = .data$median_drug_exposure_days_q05_q95,
        `Neg. Days n (%)` = .data$proportion_of_records_with_negative_drug_exposure_days
      )
  }
  return(ded_results)
}

.getDedVersion <- function(df) {
  if (!is.null(df$packageVersion)) {
    return(df$packageVersion)
  } else {
    return("Unknown")
  }
}

#' Export Performance Benchmark results to csv file
#'
#' @param results results object from \code{cdmOnboarding}
#' @param outputFolder folder to store the results
#' @return Writes to outputFolder a csv file with the Benchmark results
#' @export
#' @importFrom stats setNames
exportPerformanceBenchmark <- function(results, outputFolder = getwd()) {
  # Get performance results
  performanceResults <- results$performanceResults

  # Combine all benchmarks to one dataframe, add a column for the benchmark type, the analysis name and the time taken
  if (!is.null(performanceResults$cdmConnectorBenchmark$result)) {
    cdmConnectorBenchmark <- performanceResults$cdmConnectorBenchmark$result |>
      mutate(
        task = .data$task,
        time_taken_secs = .data$time_taken_secs,
        .keep = 'none'
      )
  }  
  if (!is.null(performanceResults$analyticsBenchmark$result)) {
    analyticsBenchmark <- performanceResults$analyticsBenchmark$result |>
      mutate(
        task = .data$task,
        time_taken_secs = .data$time_taken_secs,
        .keep = 'none'
      )
  }
  if (!is.null(performanceResults$cohortBenchmark)) {
    cohortBenchmark <- performanceResults$cohortBenchmark |>
      mutate(
        task = .data$task,
        time_taken_secs = .data$time_taken_secs,
        .keep = 'none'
      )
  }

  benchmarkResults <- bind_rows(
    if (exists("cdmConnectorBenchmark")) cdmConnectorBenchmark else NULL,
    if (exists("analyticsBenchmark")) analyticsBenchmark else NULL,
    if (exists("cohortBenchmark")) cohortBenchmark else NULL
  ) |> mutate(
    timeTaken = prettyunits::pretty_sec(.data$time_taken_secs),
    .keep = 'unused'
  )
  
  # Metadata
  metadata <- c(
    sprintf("Execution Date: %s", results$executionDate),
    sprintf("Source Release Date: %s", results$cdmSource$SOURCE_RELEASE_DATE),
    sprintf("CDM Release Date: %s", results$cdmSource$CDM_RELEASE_DATE)
  )
  metadata <- setNames(c(metadata, rep(NA, ncol(benchmarkResults) - length(metadata))), names(benchmarkResults))

  # Write results with metadata
  outputFilename <- sprintf('benchmark_results_%s_%s.csv', results$databaseId, format(Sys.time(), "%Y%m%d"))
  benchmarkResults %>%
    rbind(metadata) %>%
    write.csv(
      file = file.path(outputFolder, outputFilename),
      row.names = TRUE # first column will be removed when uploading to portal
    )

  ParallelLogger::logInfo(sprintf("> Benchmark results written to '%s'", file.path(outputFolder, outputFilename)))
}