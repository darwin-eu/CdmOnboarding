# @file generateDedSection.R
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

#' Generates the Drug Exposure Diagnostics section for the Results Document
#'
#' @param doc officer document object to add the section to
#' @param df Results object from \code{cdmOnboarding}
generateDedSection <- function(doc, df) {
  # Backwards compatibility with 2.1 where df was not wrapped in result object + duration.
  if (!('result' %in% names(df))) {
    df <- list(result = df, duration = NULL)
  }

  dedVersion <- .getDedVersion(df)

  df$result <- .formatDedResults(df$result, dedVersion)

  doc <- doc %>%
    my_table_caption(
      paste(
        "Drug Exposure Diagnostics results for selected ingredients, covering different types of products.",
        "Executed with minCellCount = 5, sample = 1e+06, earliestStartDate = 2010-01-01.",
        "#Records = Number of records.",
        "#Persons = Number of unique persons.",
        "Type (n,%) = Frequency and percentage of available drug types.",
        "Route (n,%) = Frequency and percentage of available routes.",
        "Dose Form present n (%) = Frequency and percentage with dose form present.",
        "Missingness n (%) = Independent missingness of quantity, drug exposure start date, drug exposure end date, and days supply.",
        "Dose available = The count of records for which dose estimation is theoretically possible and how many of are missing due to missing values.",
        "Dose distrib. = Distribution of calculated daily dose per unit (media q05-q95 [unit]).",
        "Quantity distrib. = Distribution of quantity (median q05-q95), frequency and percentage of null or missing quantity.",
        "Exposure days distrib. = Distribution of exposure days (median q05-q95), frequency and percentage of null days_supply or missing exposure dates.",
        "Neg. Days n (%) = Frequency and percentage of negative exposure days.",
        "More information: https://darwin-eu.github.io/DrugExposureDiagnostics/articles/DiagnosticsSummary.html",
        "DrugExposureDiagnostics version:",
        dedVersion
      ),
      sourceSymbol = pkg.env$sources$cdm
    ) %>%
    my_body_add_table_runtime(df)

  if (!is.null(df$resultMappingLevel)) {
    df$resultMappingLevel$n_records <- format(round(df$resultMappingLevel$n_records / 10) * 10, big.mark = ",", format = 'd')

    df$resultMappingLevel <- df$resultMappingLevel %>%
      select(
        `Ingredient` = .data$ingredient,
        `Concept Class` = .data$concept_class,
        `#Concepts` = .data$n_concepts,
        `#Records` = .data$n_records
      )

    doc <- doc %>%
      my_table_caption(
        "Target concept classes of selected ingredients.",
        sourceSymbol = pkg.env$sources$cdm
      ) %>%
      my_body_add_table(df$resultMappingLevel)
  }

  return(doc)
}
