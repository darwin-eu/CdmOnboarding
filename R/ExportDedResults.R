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
#' @export
exportDedResults <- function(
  path
) {
  results <- readRDS(path)
  outputFolder <- dirname(path)
  .exportDedResults(results, outputFolder)
}

#' Export DrugExposureDiagnostics results to csv file
#'
#' @param results results object from \code{cdmOnboarding}
#' @param outputFolder folder to store the results
.exportDedResults <- function(
  results,
  outputFolder = getwd(),
  ded_version = "1.0.5"
) {
  ded_results <- results$drugExposureDiagnostics$result
  if (is.null(ded_results)) {
    ParallelLogger::logInfo("No DrugExposureDiagnostics results to export")
    return()
  }

  ded_results$ingredient_concept_id <- as.character(ded_results$ingredient_concept_id)
  ded_results$n_records <- format(round(ded_results$n_records / 10) * 10, big.mark = ",", format = 'd')
  ded_results$n_patients <- format(round(ded_results$n_patients / 10) * 10, big.mark = ",", format = 'd')

  if (ded_version == '1.0.4') {
    ded_results <- ded_results %>%
      select(
        `Ingredient` = .data$ingredient,
        `#Records` = .data$n_records,
        `#Persons` = .data$n_patients,
        `Type (n,%)` = .data$proportion_of_records_by_drug_type,
        `Route (n,%)` = .data$proportion_of_records_by_route_type,
        `Dose Form present n (%)` = .data$proportion_of_records_with_dose_form,
        `Missingness` = .data$missing_quantity_exp_start_end_days_supply,
        `Dose ` = .data$n_dose_and_missingness,
        `Dose distrib.` = .data$median_daily_dose_q05_q95,
        `Quantity distrib.` = .data$median_quantity_q05_q95,
        `Exposure days distrib.` = .data$median_drug_exposure_days_q05_q95,
        `Neg. Days n (%)` = .data$proportion_of_records_with_negative_drug_exposure_days
      )
  } else if (ded_version == '1.0.4') {
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
        `Amount distrib. [null or missing]` = .data$.data$median_amount_value_q05_q95,
        `Quantity distrib. [null or missing]` = median_quantity_q05_q95,
        `Exposure days distrib. [null or missing]` = .data$median_drug_exposure_days_q05_q95,
        `Neg. Days n (%)` = .data$proportion_of_records_with_negative_drug_exposure_days
      )
  }

  ded_results %>%
    # add metadata
    add_row(
      ingredient = sprintf("Execution Date: %s", results$executionDate),
      ingredient_concept_id = sprintf("Source Release Date: %s", results$cdmSource$SOURCE_RELEASE_DATE),
      n_records = sprintf("CDM Release Date: %s", results$cdmSource$CDM_RELEASE_DATE)
    ) %>%
    write.csv(
      file = file.path(outputFolder, sprintf('ded_results_%s_%s.csv', results$databaseId, format(Sys.time(), "%Y%m%d"))),
      row.names = TRUE # first column will be removed when uploading to portal
    )
  ParallelLogger::logInfo(sprintf("DrugExposureDiagnostics results written to '%s'", file.path(outputFolder, 'ded_results.csv')))
}