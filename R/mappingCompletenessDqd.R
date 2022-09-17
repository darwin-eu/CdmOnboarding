# @file Helper
#
# Copyright 2022 Darwin EU Coordination Center
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

mappingCompletenessDqd <- function(dqdJsonPath) {
  start_time = Sys.time()

  coverage_results <- jsonlite::fromJSON(dqdJsonPath) %>%
    # standardConceptRecordCompleteness = Record Coverage,
    # sourceValueCompleteness = Term Coverage
    dplyr::filter(CHECK_NAME %in% c("standardConceptRecordCompleteness", "sourceValueCompleteness")) %>%
    # Not interested in era's as these are all derived
    dplyr::filter(!(CDM_TABLE_NAME %in% c("DRUG_ERA", "DOSE_ERA", "CONDITION_ERA"))) %>%
    # Create new variable for domain field
    dplyr::mutate(
      CDM_FIELD_NAME = toupper(CDM_FIELD_NAME),
      # Naming of domains
      domain = gsub("_(OCC\\w+|EXP\\w+|PLAN.+)$", "", CDM_TABLE_NAME),
      variable = ifelse(CHECK_NAME=="standardConceptRecordCompleteness",
                        sub('_CONCEPT_ID', '', CDM_FIELD_NAME),
                        sub('_SOURCE_VALUE', '', CDM_FIELD_NAME)
      ),
      domain_abbrev = recode(domain,
                             VISIT = "VST",
                             CONDITION = "COND",
                             PROCEDURE = "PROC",
                             OBSERVATION = "OBS",
                             MEASUREMENT = "MEAS",
                             SPECIMEN = "SPEC"
      ),
      domainField = ifelse(domain==variable,
                           domain,
                           paste0(domain_abbrev,"-",variable)
      )
    ) %>%
    # To keep things simple, we only look at the six main domains and units
    dplyr::filter(domainField %in% c("VISIT", "PROCEDURE", "DRUG", "CONDITION", "MEASUREMENT",
                              "OBSERVATION", "MEAS-UNIT", "OBS-UNIT", "PROVIDER-SPECIALTY",
                              "COND-CONDITION_STATUS", "SPECIMEN", "DEVICE", "DEATH-CAUSE")
                            # DQD does not report standard concept completeness on  "MEAS-VALUE" and "OBS-VALUE"
    ) %>%
    dplyr::transmute(
      CHECK_NAME,
      domainField,
      total = NUM_DENOMINATOR_ROWS,
      mapped = NUM_DENOMINATOR_ROWS - NUM_VIOLATED_ROWS,
      coveragePct = (1 - PCT_VIOLATED_ROWS) * 100,
    ) %>%
    tidyr::pivot_wider(
      names_from = CHECK_NAME,
      values_from = c(mapped, total, coveragePct)
    ) %>%
    dplyr::select(
      DOMAIN = domainField,
      '#CODES SOURCE' = total_sourceValueCompleteness,
      '#CODES MAPPED' = mapped_sourceValueCompleteness,
      '%CODES MAPPED' = coveragePct_sourceValueCompleteness,
      '#RECORDS SOURCE' = total_standardConceptRecordCompleteness,
      '#RECORDS MAPPED' = mapped_standardConceptRecordCompleteness,
      '%RECORDS MAPPED' = coveragePct_standardConceptRecordCompleteness,
    ) %>%
    dplyr::arrange(
      DOMAIN
    )

  result <- list(
    result = mappingCoverages,
    duration = as.numeric(difftime(Sys.time(), start_time), units="secs")
  )
  return(result)
}
