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

#' Export DrugExposureDiagnostics results to csv file in same folder as input path
#'
#' @param path path to the CdmOnboarding .rds results file
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
  outputFolder = getwd()
) {
  ded_results <- results$drugExposureDiagnostics$result
  if (is.null(ded_results)) {
    ParallelLogger::logInfo("No DrugExposureDiagnostics results to export")
  }
  ded_results %>%
    select(
      `Ingredient` = ingredient,
      `Concept ID` = ingredient_concept_id,
      `#` = n_records,
      `Type (n,%)` = proportion_of_records_by_drug_type,
      `Route (n,%)` = proportion_of_records_by_route_type,
      `Dose Form present n (%)` = proportion_of_records_with_dose_form,
      `Fixed amount dose form n (%)` = proportion_of_records_missing_denominator_unit_concept_id,
      `Amount distrib. [null or missing]` = median_amount_value_q05_q95,
      `Quantity distrib. [null or missing]` = median_quantity_q05_q95,
      `Exposure days distrib. [null or missing]` = median_drug_exposure_days_q05_q95,
      `Neg. Days n (%)` = proportion_of_records_with_negative_drug_exposure_days
    ) %>%
    write.csv(
      file = file.path(outputFolder, sprintf('ded_results_%s_%s.csv', results$databaseId, format(Sys.time(), "%Y%m%d"))),
      row.names = FALSE
    )
  ParallelLogger::logInfo(sprintf("DrugExposureDiagnostics results written to '%s'", file.path(outputFolder, 'ded_results.csv')))
}