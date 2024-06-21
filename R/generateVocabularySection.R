# @file generateVocabularySection.R
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


#' Generates the Vocabulary Section in the Results Document
#'
#' @param doc officer document object to add the section to
#' @param df Results object from \code{cdmOnboarding}
generateVocabularySection <- function(doc, df) {
  doc <- doc %>%
    officer::body_add_par(
      sprintf(
        "Vocabulary version: %s",
        dplyr::coalesce(df$version, "Not available")
      )
    )
  }

  if (!is.null(df$mappingTempTableCreation$duration)) {
    doc <- doc %>%
      officer::body_add_par(
        sprintf(
          "Pre-processing query executed in %.2f seconds",
          df$mappingTempTableCreation$duration
        ),
        style = pkg.env$styles$footnote
      )
  }

  # Mapping Completeness
  if (!is.null(df$mappingCompleteness$result)) {
    # TODO: report all missing values at the end of execution
    df$mappingCompleteness$result <- df$mappingCompleteness$result %>%
      arrange(DOMAIN) %>%
      mutate(
        Domain = DOMAIN,
        `#Codes Source` = N_CODES_SOURCE,
        `#Codes Mapped` = N_CODES_MAPPED,
        `%Codes Mapped` = prettyPc(P_CODES_MAPPED),
        `#Records Source` = N_RECORDS_SOURCE,
        `#Records Mapped` = N_RECORDS_MAPPED,
        `%Records Mapped` = prettyPc(P_RECORDS_MAPPED),
        .keep = "none"  # do not display other columns
      )
  }

  doc <- doc %>%
    officer::body_add_par("Mapping Completeness", style = pkg.env$styles$heading2) %>%
    my_table(
      data = df$mappingCompleteness,
      caption = paste(
        "The number and percentage of codes and records that are mapped to an OMOP concept (not 0 and <2B)."
        , "Note: for one-to-many mappings, the source codes will be counted multiple times so the reported total source codes"
        , "could be bigger than actual number of unique source codes."
      ),
      sourceSymbol = pkg.env$sources$cdm,
      alignment =  c('l', rep('r', 6))
    )

  # Drug Level Mappings
  if (!is.null(df$drugMapping$result)) {
    df$drugMapping$result <- df$drugMapping$result %>%
      arrange(desc(N_RECORDS)) %>%
      mutate(
        Class = CLASS,
        `#Records` = N_RECORDS,
        `#Patients` = N_PATIENTS,
        `#Codes` = N_SOURCE_CODES,
        `%Records` = prettyPc(P_RECORDS),
        .keep = "none"  # do not display other columns
      )
  }
  doc <- doc %>%
    officer::body_add_par("Drug Mappings", style = pkg.env$styles$heading2) %>%
    my_table(
      data = df$drugMapping,
      caption = "The level of the drug mappings",
      sourceSymbol = pkg.env$sources$cdm,
      alignment =  c('l', rep('r', 4))
    )

  # Top 25 unmapped codes
  doc <- doc %>%
    officer::body_add_par("Unmapped Codes", style = pkg.env$styles$heading2) %>%
    my_unmapped_section(df$unmappedDrugs, "drugs", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedConditions, "conditions", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedMeasurements, "measurements", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedObservations, "observations", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedProcedures, "procedures", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedDevices, "devices", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedVisits, "visits", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedVisitDetails, "visit details", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedUnitsMeas, "measurement units", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedUnitsObs, "observation units", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedValuesMeas, "measurement values", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedValuesObs, "observation values", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedDrugRoute, "drug route", results$smallCellCount) %>%
    my_unmapped_section(df$unmappedSpecialty, "specialty", results$smallCellCount)

  # Top 25 mapped concepts
  doc <- doc %>%
    officer::body_add_par("Mapped Codes", style = pkg.env$styles$heading2) %>%
    my_mapped_section(df$mappedDrugs, "drugs", results$smallCellCount) %>%
    my_mapped_section(df$mappedConditions, "conditions", results$smallCellCount) %>%
    my_mapped_section(df$mappedMeasurements, "measurements", results$smallCellCount) %>%
    my_mapped_section(df$mappedObservations, "observations", results$smallCellCount) %>%
    my_mapped_section(df$mappedProcedures, "procedures", results$smallCellCount) %>%
    my_mapped_section(df$mappedDevices, "devices", results$smallCellCount) %>%
    my_mapped_section(df$mappedVisits, "visits", results$smallCellCount) %>%
    my_mapped_section(df$mappedVisitDetails, "visit details", results$smallCellCount) %>%
    my_mapped_section(df$mappedUnitsMeas, "measurement units", results$smallCellCount) %>%
    my_mapped_section(df$mappedUnitsObs, "observation units", results$smallCellCount) %>%
    my_mapped_section(df$mappedValuesMeas, "measurement values", results$smallCellCount) %>%
    my_mapped_section(df$mappedValuesObs, "observation values", results$smallCellCount) %>%
    my_mapped_section(df$mappedDrugRoute, "drug route", results$smallCellCount) %>%
    my_mapped_section(df$mappedSpecialty, "specialty", results$smallCellCount)

  doc <- doc %>%
    officer::body_add_par("Source to concept map", style = pkg.env$styles$heading2) %>%
    my_table(
      data = df$sourceConceptFrequency,
      caption = "The number of records per source concept.",
      sourceSymbol = pkg.env$sources$cdm
    ) %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Note that the full source_to_concept_map table is added in the results rds", style = pkg.env$styles$highlight) %>%
    officer::body_add_break()

  return(doc)
}
