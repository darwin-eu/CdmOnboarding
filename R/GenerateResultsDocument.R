# @file GenerateResultsDocument
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

# Makes styles globally available, also for helper functions
pkg.env <- new.env(parent = emptyenv())
pkg.env$styles <- list(
  title = "Doc title (Agency)",
  subTitle = "Doc subtitle (Agency)",
  heading1 = "Heading 1 (Agency)",
  heading2 = "Heading 2 (Agency)",
  table = "Table grid (Agency)",
  tableCaption = "Table heading (Agency)",
  figureCaption = "Figure heading (Agency)",
  highlight = "Drafting Notes (Agency)",
  footnote = "Footnote text (Agency)"
)

pkg.env$sources <- list(
  cdm = "\u24C4",  # O in circle
  achilles = "\u24B6",  # A in circle
  system = "\u24C8"  # S in circle
)


#' Generates the Results Document
#'
#' @description
#' \code{generateResultsDocument} creates a word document with results based on a template
#' @param results             Results object from \code{cdmOnboarding}
#' @param outputFolder        Folder to store the results
#' @param authors             List of author names to be added in the document
#' @export
generateResultsDocument <- function(results, outputFolder, authors) {
  # New document from the template
  docTemplate <- system.file("templates", "Template-CdmOnboarding.docx", package = "CdmOnboarding")
  doc <- officer::read_docx(path = docTemplate)

  # Title Page
  doc <- doc %>%
    officer::body_add_par(
      sprintf("CDM Onboarding report for the %s database", results$databaseName),
      style = pkg.env$styles$title
    ) %>%
    officer::body_add_par(paste(authors, collapse = ","), style = pkg.env$styles$subTitle) %>%
    officer::body_add_break()

  # Table of content
  doc <- doc %>%
    officer::body_add_par("Table of content", style = pkg.env$styles$heading1) %>%
    officer::body_add_toc(level = 2) %>%
    officer::body_add_break()

  # Execution details
  doc <- doc %>%
    officer::body_add_par("Execution details", style = pkg.env$styles$heading1)

  doc <- generateExecutionDetails(doc, results)

  doc <- doc %>% officer::body_add_break()

  counts_optimized <- results$runWithOptimizedQueries && results$dms %in% c("postgresql", "sqlserver")

  # Data Tables section
  doc <- doc %>%
    officer::body_add_par("Clinical data", style = pkg.env$styles$heading1)
  if (!is.null(results$dataTablesResults)) {
    doc <- generateDataTablesSection(doc, results$dataTablesResults, cdmSource = results$cdmSource, optimized = counts_optimized)
  } else {
    doc <- doc %>%
      officer::body_add_par("Clinical data tables have not been retrieved, runDataTables = FALSE?", style = pkg.env$styles$highlight)
  }

  ## Vocabulary checks section
  doc <- doc %>%
    officer::body_add_par("Vocabulary mappings", style = pkg.env$styles$heading1)
  if (!is.null(results$vocabularyResults)) {
    doc <- generateVocabularySection(doc, results$vocabularyResults, smallCellCount = results$smallCellCount)
  } else {
    doc <- doc %>%
      officer::body_add_par("Vocabulary checks have not been executed, runVocabularyChecks = FALSE?", style = pkg.env$styles$highlight)
  }

  # Data Quality Dashboard
  doc <- doc %>%
    officer::body_add_par("Data Quality Dashboard", style = pkg.env$styles$heading1)
  if (!is.null(results$dqdResults)) {
    doc <- generateDqdSection(doc, results$dqdResults)
  } else {
    doc <- doc %>%
      officer::body_add_par("DataQualityDashboard results have not been provided, dqdJsonPath = NULL?", style = pkg.env$styles$highlight)
  }

  # Drug Exposure Diagnostics
  doc <- doc %>%
    officer::body_end_section_portrait() %>%
    officer::body_add_par("Drug Exposure Diagnostics", style = pkg.env$styles$heading1)

  if (!is.null(results$drugExposureDiagnostics)) {
    doc <- generateDedSection(doc, results$drugExposureDiagnostics)
  } else {
    doc <- doc %>%
      officer::body_add_par("Drug Exposure Diagnostics results are missing, runDedChecks = FALSE?", style = pkg.env$styles$highlight)
  }

  doc <- doc %>% officer::body_end_section_landscape()

  doc <- doc %>%
    officer::body_add_par("Technical Infrastructure", style = pkg.env$styles$heading1)

  if (!is.null(results$performanceResults)) {
    doc <- generatePerformanceSection(doc, results) # performance section also requires other results
  } else {
    doc <- doc %>%
      officer::body_add_par("Performance checks have not been executed, runPerformanceChecks = FALSE?", style = pkg.env$styles$highlight)
  }

  if (!is.null(results$cohortBenchmark)) {
    doc <- generateCohortBenchmarkSection(doc, results$cohortBenchmark)
  } else {
    doc <- doc %>%
      officer::body_add_par("Cohort Benchmark results are missing, runCohortBenchmark = FALSE?", style = pkg.env$styles$highlight)
  }

  doc <- doc %>%
    officer::body_add_par("Appendix", style = pkg.env$styles$heading1)
  if (!is.null(results$vocabularyResults)) {
    doc <- generateAppendixSection(doc, results$vocabularyResults, optimized = counts_optimized)
  } else {
    doc <- doc %>%
      officer::body_add_par("Appendix could not be generated, runVocabularyChecks = FALSE?", style = pkg.env$styles$highlight)
  }

  ## save the doc as a word file
  outputFile <- file.path(outputFolder, sprintf("CdmOnboarding_%s_%s.docx", results$databaseId, format(Sys.time(), "%Y%m%d")))
  ParallelLogger::logInfo("> Saving doc to ", outputFile)
  print(doc, target = outputFile)
}
