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

#' Generates the Cohort Benchmark section for the Results Document
#'
#' @param doc officer document object to add the section to
#' @param df Results object from \code{cdmOnboarding}
generateCohortBenchmarkSection <- function(doc, df) {
  df %>%
    mutate(
      `Cohort` = .data$cohort_name,
      `#Records` = .data$n_records,
      `#Persons` = .data$n_subjects,
      `Duration (s)` = round(.data$duration, 2),
      `Error` = .data$error
    )

  doc <- doc %>%
    my_table_caption('Results from generating cohort benchmark.',
      sourceSymbol = pkg.env$sources$cdm
    ) %>%
    my_body_add_table(df)

  return(doc)
}
