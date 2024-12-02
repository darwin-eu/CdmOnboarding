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
      Category = c("Plausibility", "Conformance", "Completeness"),
      Total = c(countTotalPlausibility, countTotalConformance, countTotalCompleteness),
      Pass = c(countPassedPlausibility, countPassedConformance, countPassedCompleteness),
      Fail = c(countFailedPlausibility, countFailedConformance, countFailedCompleteness)
    )
  )
  # Totals
  dqdOverview <- dqdOverview %>%
    bind_rows(summarise_all(.data, ~if (is.numeric(.)) sum(.) else "Total"))

  dqdOverview <- dqdOverview %>%
    mutate(
      Applicable = .data$Fail + .data$Pass,  # No fail/pass means check has status NA
      `%Pass` = prettyPc(.data$Pass / .data$Applicable * 100),
      .keep = 'all'
    ) %>%
    relocate(
      .data$Applicable,
      .after = .data$Total
    )

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
    my_table_caption("Number of total, applicable, passed and failed DQD checks per category. Pass percentage is calculated from total applicable checks. Checks can be not applicable if table/field it is applied to is empty.", sourceSymbol = "") %>%  #nolint
    my_body_add_table(dqdOverview, first_column = TRUE, alignment = c('l', rep('r', 4)), last_row = TRUE)

  return(doc)
}
