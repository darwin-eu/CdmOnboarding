# @file generateAppendixSection.R
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

#' Generates the Appendix section for the Results Document
#'
#' @param doc officer document object to add the section to
#' @param df Results object from \code{cdmOnboarding} vocabularyResults
#' @param optimized boolean indicating if the optimized queries were used
generateAppendixSection <- function(doc, df, optimized) {
  # add vocabulary table counts
      arrange(desc(.data$COUNT))
    doc <- doc %>%
      officer::body_add_par("Vocabulary table counts", style = pkg.env$styles$heading2) %>%
      my_table_caption("The number of records in all vocabulary tables.", sourceSymbol = if (optimized) pkg.env$sources$system else pkg.env$sources$cdm) %>% #nolint
  }

  # vocabularies table
    doc <- doc %>%
      officer::body_add_par("Vocabulary concept counts", style = pkg.env$styles$heading2) %>%
      officer::body_add_par(sprintf("Vocabulary version: %s", results$vocabularyResults$version)) %>%
      my_table_caption("The vocabularies available in the CDM with concept count. Note that this does not reflect which concepts are actually used in the clinical CDM tables. S=Standard, C=Classification and '-'=Non-standard", sourceSymbol = pkg.env$sources$cdm) %>% #nolint
  }
}
