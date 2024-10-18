# @file generateDqdSection.R
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

#' Generates the DQD section for the Results Document
#'
#' @param doc officer document object to add the section to
#' @param df Results object from \code{cdmOnboarding}
generateDqdSection <- function(doc, df) {
  dqdOverview <- with(
    df$overview,
    data.frame(
      Category = c("Plausibility", "Conformance", "Completeness", "Total"),
      Pass = c(countPassedPlausibility, countPassedConformance, countPassedCompleteness, countPassed),
      Fail = c(countFailedPlausibility, countFailedConformance, countFailedCompleteness, countOverallFailed),
      Total = c(countTotalPlausibility, countTotalConformance, countTotalCompleteness, countTotal)
    )
  )
  dqdOverview$NotApplicable <- dqdOverview$Total - dqdOverview$Fail - dqdOverview$Pass
  dqdOverview$`%Pass` <- prettyPc(dqdOverview$Pass / (dqdOverview$Total - dqdOverview$NotApplicable) * 100)

  doc <- doc %>%
    officer::body_add_par(sprintf(
      "DataQualityDashboard Version: %s",
      df$version[1]
    )) %>%
    officer::body_add_par(sprintf(
      "DataQualityDashboard executed at %s in %s.",
      df$startTimestamp,
      df$executionTime
    )) %>%
    my_table_caption("Number of passed, failed and total DQD checks per category.", sourceSymbol = "") %>%
    my_body_add_table(dqdOverview, first_column = TRUE, alignment = c('l', rep('r', 4)), last_row = TRUE)

  return(doc)
}
