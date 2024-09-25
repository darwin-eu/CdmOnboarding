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
#' @param smallCellCount number of cells to display in the unmapped/mapped tables
generateVocabularySection <- function(doc, df, smallCellCount) {
  doc <- doc %>%
    officer::body_add_par(
      sprintf(
        "Vocabulary version: %s",
        dplyr::coalesce(df$version, "Not available")
      )
    )

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
      arrange(.data$DOMAIN) %>%
      mutate(
        Domain = .data$DOMAIN,
        `#Codes Source` = .data$N_CODES_SOURCE,
        `#Codes Mapped` = .data$N_CODES_MAPPED,
        `%Codes Mapped` = prettyPc(.data$P_CODES_MAPPED),
        `#Records Source` = .data$N_RECORDS_SOURCE,
        `#Records Mapped` = .data$N_RECORDS_MAPPED,
        `%Records Mapped` = prettyPc(.data$P_RECORDS_MAPPED),
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
      arrange(desc(.data$N_RECORDS)) %>%
      mutate(
        Class = .data$CLASS,
        `#Records` = .data$N_RECORDS,
        `#Patients` = .data$N_PATIENTS,
        `#Codes` = .data$N_SOURCE_CODES,
        `%Records` = prettyPc(.data$P_RECORDS),
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
    my_unmapped_section(df$unmappedDrugs, "drugs", smallCellCount) %>%
    my_unmapped_section(df$unmappedConditions, "conditions", smallCellCount) %>%
    my_unmapped_section(df$unmappedMeasurements, "measurements", smallCellCount) %>%
    my_unmapped_section(df$unmappedObservations, "observations", smallCellCount) %>%
    my_unmapped_section(df$unmappedProcedures, "procedures", smallCellCount) %>%
    my_unmapped_section(df$unmappedDevices, "devices", smallCellCount) %>%
    my_unmapped_section(df$unmappedVisits, "visits", smallCellCount) %>%
    my_unmapped_section(df$unmappedVisitDetails, "visit details", smallCellCount) %>%
    my_unmapped_section(df$unmappedUnitsMeas, "measurement units", smallCellCount) %>%
    my_unmapped_section(df$unmappedUnitsObs, "observation units", smallCellCount) %>%
    my_unmapped_section(df$unmappedValuesMeas, "measurement values", smallCellCount) %>%
    my_unmapped_section(df$unmappedValuesObs, "observation values", smallCellCount) %>%
    my_unmapped_section(df$unmappedDrugRoute, "drug route", smallCellCount) %>%
    my_unmapped_section(df$unmappedSpecialty, "specialty", smallCellCount) %>%
    my_unmapped_section(df$unmappedEpisodes, "episode", smallCellCount)

  # Top 25 mapped concepts
  doc <- doc %>%
    officer::body_add_par("Mapped Codes", style = pkg.env$styles$heading2) %>%
    my_mapped_section(df$mappedDrugs, "drugs", smallCellCount) %>%
    my_mapped_section(df$mappedConditions, "conditions", smallCellCount) %>%
    my_mapped_section(df$mappedMeasurements, "measurements", smallCellCount) %>%
    my_mapped_section(df$mappedObservations, "observations", smallCellCount) %>%
    my_mapped_section(df$mappedProcedures, "procedures", smallCellCount) %>%
    my_mapped_section(df$mappedDevices, "devices", smallCellCount) %>%
    my_mapped_section(df$mappedVisits, "visits", smallCellCount) %>%
    my_mapped_section(df$mappedVisitDetails, "visit details", smallCellCount) %>%
    my_mapped_section(df$mappedUnitsMeas, "measurement units", smallCellCount) %>%
    my_mapped_section(df$mappedUnitsObs, "observation units", smallCellCount) %>%
    my_mapped_section(df$mappedValuesMeas, "measurement values", smallCellCount) %>%
    my_mapped_section(df$mappedValuesObs, "observation values", smallCellCount) %>%
    my_mapped_section(df$mappedDrugRoute, "drug route", smallCellCount) %>%
    my_mapped_section(df$mappedSpecialty, "specialty", smallCellCount) %>%
    my_mapped_section(df$mappedEpisodes, "episode", smallCellCount)

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
