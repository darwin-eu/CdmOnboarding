# @file generateExecutionDetailsSection.R
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

#' Generates the Execution Details section for the Results Document
#'
#' @param doc officer document object to add the section to
#' @param df Results object from \code{cdmOnboarding}
generateExecutionDetails <- function(doc, df) {
  metadata <- data.frame(rbind(
    c("CdmOnboarding package version", paste0(
      results$cdmOnboardingVersion,
      if (df$runWithOptimizedQueries) ' (performance optimized=TRUE)' else ''
    )),
    c("Database", df$dms),
    c("CDM version", df$cdmSource$CDM_VERSION),
    c("Execution date", df$executionDate),
    c("Execution duration", prettyunits::pretty_sec(df$executionDuration)),
    c("Achilles version", df$achillesMetadata$ACHILLES_VERSION),
    c("Achilles execution date", df$achillesMetadata$ACHILLES_EXECUTION_DATE)
  ))
  names(metadata) <- c('Detail', 'Value')

  doc <- doc %>%
    my_body_add_table(metadata) %>%
    # Explanation of symbols
    officer::body_add_par(
      sprintf(
        "Symbols used in table/figure captions: %s=Computed directly from OMOP CDM data, %s=Computed from Achilles, %s=Estimated from system tables.", # nolint
        pkg.env$sources$cdm,
        pkg.env$sources$achilles,
        pkg.env$sources$system
      )
    )

  # CDM Source
  t_cdmSource <- data.table::transpose(df$cdmSource)
  colnames(t_cdmSource) <- c('Values')
  field <- colnames(df$cdmSource)
  t_cdmSource <- cbind(field, t_cdmSource)
  doc <- doc %>%
    officer::body_add_par("CDM Source Table", style = pkg.env$styles$heading2) %>%
    my_table_caption("Content of the OMOP cdm_source table", sourceSymbol = pkg.env$sources$cdm) %>%
    my_body_add_table(t_cdmSource)

  return(doc)
}
