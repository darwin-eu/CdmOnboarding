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
  result <- jsonlite::fromJSON(dqdJsonPath)
  check_results <- result$CheckResults %>%
    select(CHECK_NAME, CDM_TABLE_NAME, CDM_FIELD_NAME,
           NUM_VIOLATED_ROWS, NUM_DENOMINATOR_ROWS, PCT_VIOLATED_ROWS)

  coverage_results <- check_results %>%
    dplyr::filter(CHECK_NAME %in% c("standardConceptRecordCompleteness", "sourceValueCompleteness")) %>%
    # Not interested in era's as these are all derived
    dplyr::filter(!(CDM_TABLE_NAME %in% c("DRUG_ERA", "DOSE_ERA", "CONDITION_ERA"))) %>%
    dplyr::mutate(
      CDM_FIELD_NAME = toupper(CDM_FIELD_NAME),
      # First check is over all records, second over the unique source terms
      coverageType = recode(CHECK_NAME,
                            standardConceptRecordCompleteness = "Records",
                            sourceValueCompleteness = "Terms"),
      # Coverage is rows not failing
      coveragePct = 1 - PCT_VIOLATED_ROWS,
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
    )

  # Mapping coverage table
  mappingCoverages <- coverage_results %>%
    # To keep things simple, we only look at the six main domains and units
    dplyr::filter(domainField %in% c("VISIT", "PROCEDURE", "DRUG", "CONDITION", "MEASUREMENT",
                              "OBSERVATION", "MEAS-UNIT", "OBS-UNIT", "PROVIDER-SPECIALTY",
                              "COND-CONDITION_STATUS", "SPECIMEN", "DEVICE")
                            #"DEATH-CAUSE", "MEAS-VALUE", "OBS-VALUE",
    ) %>%
    dplyr::transmute(
      domainField,
      coverageType,
      mapped = NUM_DENOMINATOR_ROWS - NUM_VIOLATED_ROWS,
      total = NUM_DENOMINATOR_ROWS,
      coveragePct = (1 - PCT_VIOLATED_ROWS) * 100
    ) %>%
    tidyr::pivot_wider(
      names_from = coverageType,
      values_from = c(mapped, total, coveragePct)
    ) %>%
    dplyr::select(
      DOMAIN = domainField,
      '#CODES SOURCE' = total_Terms,
      '#CODES MAPPED' = mapped_Terms,
      '%CODES MAPPED' = coveragePct_Terms,
      '#RECORDS SOURCE' = total_Records,
      '#RECORDS MAPPED' = mapped_Records,
      '%RECORDS MAPPED' = coveragePct_Records,
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
