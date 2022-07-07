# @file GenerateResultsDocument
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
# @author Peter Rijnbeek
# @author Maxim Moinat

# Makes styles globally available, also for helper functions
pkg.env <- new.env(parent = emptyenv())
pkg.env$styles <- list(
  title="Doc title (Agency)",
  subTitle="Doc subtitle (Agency)",
  heading1="Heading 1 (Agency)",
  heading2="Heading 2 (Agency)",
  table="Table grid (Agency)",
  tableCaption="Table heading (Agency)",
  figureCaption="Figure heading (Agency)",
  highlight="Drafting Notes (Agency)",
  footnote="Footnote text (Agency)"
)

#' Generates the Results Document
#'
#' @description
#' \code{generateResultsDocument} creates a word document with results based on a template
#' @param results             Results object from \code{cdmOnboarding}
#' @param outputFolder        Folder to store the results
#' @param authors             List of author names to be added in the document
#' @param databaseId          Id of the database
#' @param databaseName        Name of the database
#' @param databaseDescription Description of the database
#' @param smallCellCount      Date with less than this number of patients are removed
#' @param silent              Flag to not create output in the terminal (default = FALSE)
#' @export
generateResultsDocument<- function(results, outputFolder, authors = "Author Names", databaseId, databaseName, databaseDescription, smallCellCount, silent=FALSE) {
  docTemplate <- system.file("templates", "Template-DarwinEU.docx", package="CdmOnboarding")
  logo <- system.file("templates", "img", "darwin-logo.jpg", package="CdmOnboarding")

  ## open a new doc from the doctemplate
  doc<-officer::read_docx(path = docTemplate)
  ## add Title Page
  doc<- doc %>%
    officer::body_add_img(logo, width = 5.00, height = 2.39) %>%
    officer::body_add_par(value = paste0("CDM Onboarding report for the ",databaseName," database"), style = pkg.env$styles$title) %>%
    officer::body_add_par(value = paste0("Package Version: ", packageVersion("CdmOnboarding")), style = pkg.env$styles$subTitle) %>%
    officer::body_add_par(value = paste0("Date: ", date()), style = pkg.env$styles$subTitle) %>%
    officer::body_add_par(value = paste0("Authors: ", authors), style = pkg.env$styles$subTitle) %>%
    officer::body_add_break()

  ## add Table of content
  doc<-doc %>%
    officer::body_add_par(value = "Table of content", style = pkg.env$styles$heading1) %>%
    officer::body_add_toc(level = 2) %>%
    officer::body_add_break()

  ## add Concept counts
  if (!is.null(results$dataTablesResults)) {
    df_t1 <- results$dataTablesResults$dataTablesCounts$result
    doc<-doc %>%
      officer::body_add_par(value = "Clinical data", style = pkg.env$styles$heading1) %>%
      officer::body_add_par(value = "Record counts per OMOP CDM table", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("The number of records in all clinical data tables", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value = df_t1[order(df_t1$COUNT, decreasing=TRUE),], style = pkg.env$styles$table) %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", results$dataTablesResults$dataTablesCounts$duration),"secs"), style = pkg.env$styles$footnote)

    plot <- recordsCountPlot(as.data.frame(results$dataTablesResults$totalRecords$result))
    doc<-doc %>% officer::body_add_break() %>%
      officer::body_add_par(value = "Data density plots", style = pkg.env$styles$heading2) %>%
      officer::body_add_gg(plot, height=4) %>%
      officer::body_add_par("Total record count over time per OMOP data domain", style = pkg.env$styles$figureCaption)

    plot <- recordsCountPlot(as.data.frame(results$dataTablesResults$recordsPerPerson$result))
    doc<-doc %>%
      officer::body_add_gg(plot, height=4) %>%
      officer::body_add_par("Number of records per person over time per OMOP data domain", style = pkg.env$styles$figureCaption)

    colnames(results$dataTablesResults$conceptsPerPerson$result) <- c("Domain", "Min", "P10", "P25", "MEDIAN", "P75", "P90", "Max")
    doc<-doc %>% officer::body_add_break() %>%
      officer::body_add_par(value = "Distinct concepts per person", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("The number of distinct concepts per person for all OMOP data domains", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value = results$dataTablesResults$conceptsPerPerson$result, style = pkg.env$styles$table) %>%
      officer::body_add_par(" ")
  }


  ## Vocabulary checks section
  doc<-doc %>%
    officer::body_add_par(value = "Vocabulary Mapping", style = pkg.env$styles$heading1)

  vocabResults <-results$vocabularyResults
  if (!is.null(vocabResults)) {
    #vocabularies table
    doc<-doc %>%
      officer::body_add_par(value = "Vocabularies", style = pkg.env$styles$heading2) %>%
      officer::body_add_par(paste0("Vocabulary version: ",results$vocabularyResults$version)) %>%
      officer::body_add_par("The vocabularies available in the CDM with concept count. Note that this does not reflect which concepts are actually used in the clinical CDM tables. S=Standard, C=Classification and '-'=Non-standard", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value = vocabResults$conceptCounts$result, style = pkg.env$styles$table) %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$conceptCounts$duration),"secs"), style = pkg.env$styles$footnote)

    ## add vocabulary table counts

    doc <- doc %>%
      officer::body_add_par(value = "Table counts", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("Shows the number of records in all vocabulary tables", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value = vocabResults$vocabularyCounts$result, style = pkg.env$styles$table) %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$vocabularyCounts$duration),"secs"), style = pkg.env$styles$footnote)

    ## add Mapping Completeness
    vocabResults$mappingCompleteness$result$'%Codes Mapped' <- prettyHr(vocabResults$mappingCompleteness$result$'%Codes Mapped')
    vocabResults$mappingCompleteness$result$'%Records Mapped' <- prettyHr(vocabResults$mappingCompleteness$result$'%Records Mapped')

    doc<-doc %>%
      officer::body_add_par(value = "Mapping Completeness", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("Shows the percentage of codes that are mapped to the standardized vocabularies as well as the percentage of records.", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value = vocabResults$mappingCompleteness$result, style = pkg.env$styles$table, alignment = c('l', rep('r',6))) %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$mappingCompleteness$duration),"secs"), style = pkg.env$styles$footnote)

    ## add Drug Level Mappings
    doc<-doc %>%
      officer::body_add_par(value = "Drug Mappings", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("The level of the drug mappings", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value = vocabResults$drugMapping$result, style = pkg.env$styles$table) %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$drugMapping$duration),"secs"), style = pkg.env$styles$footnote)

    ## add Top 25 missing mappings
    doc<-doc %>%
      officer::body_add_par(value = "Unmapped Codes", style = pkg.env$styles$heading2)
    my_unmapped_section(doc, vocabResults$unmappedDrugs, "drugs", smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedConditions, "conditions", smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedMeasurements, "measurements", smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedObservations, "observations",smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedProcedures, "procedures", smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedDevices, "devices", smallCellCount)

    ## add top 25 mapped codes
    doc<-doc %>%
      officer::body_add_par(value = "Mapped Codes", style = pkg.env$styles$heading2)
    my_mapped_section(doc, vocabResults$mappedDrugs, "drugs", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedConditions, "conditions", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedMeasurements, "measurements", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedObservations, "observations", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedProcedures, "procedures", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedDevices, "devices", smallCellCount)

    ## add source_to_concept_map breakdown
    doc<-doc %>%
      officer::body_add_par(value = "Source to concept map", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("Source to concept map breakdown", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value = vocabResults$sourceConceptFrequency$result, style = pkg.env$styles$table) %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$sourceConceptFrequency$duration),"secs"), style = pkg.env$styles$footnote) %>%
      officer::body_add_par("Note that the full source_to_concept_map table is added in the results.zip", style="Drafting Notes (Agency)")

  } else {
    doc<-doc %>%
    officer::body_add_par("Vocabulary checks have not been executed, runVocabularyChecks = FALSE?", style="Drafting Notes (Agency)") %>%
    officer::body_add_break()
  }

  doc<-doc %>%
    officer::body_add_par(value = "Technical Infrastructure", style = pkg.env$styles$heading1)

  if (!is.null(results$dataTablesResults)) {
    # cdm source
    t_cdmSource <- data.table::transpose(results$cdmSource)
    colnames(t_cdmSource) <- rownames(results$cdmSource)
    field <- colnames(results$cdmSource)
    t_cdmSource <- cbind(field, t_cdmSource)
    doc<-doc %>%
      officer::body_add_par(value = "CDM Source Table", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("Content of the OMOP cdm_source table", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value =t_cdmSource, style = pkg.env$styles$table)
  }

  if (!is.null(results$performanceResults)) {
    #installed packages
    doc<-doc %>%
      officer::body_add_par(value = "HADES packages", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("Versions of all installed R packages that are relevant for DARWIN EU studies", style = pkg.env$styles$tableCaption) %>%
      my_body_add_table(value = results$hadesPackageVersions, style = pkg.env$styles$table)

    if (results$missingPackage=="") {
      doc<-doc %>%
      officer::body_add_par("All R packages were available")
    } else {
      doc<-doc %>%
      officer::body_add_par(paste0("Missing R packages: ",results$missingPackages))
    }

    #system detail
    doc<-doc %>%
      officer::body_add_par(value = "System Information", style = pkg.env$styles$heading2) %>%
      officer::body_add_par(paste0("Installed R version: ", results$sys_details$r_version$version.string)) %>%
      officer::body_add_par(paste0("System CPU vendor: ", results$sys_details$cpu$vendor_id, collapse =", ")) %>%
      officer::body_add_par(paste0("System CPU model: ", results$sys_details$cpu$model_name, collapse =", ")) %>%
      officer::body_add_par(paste0("System CPU number of cores: ", results$sys_details$cpu$no_of_cores, collapse =", ")) %>%
      officer::body_add_par(paste0("System RAM: ", prettyunits::pretty_bytes(as.numeric(results$sys_details$ram, collapse =", ")))) %>%
      officer::body_add_par(paste0("DBMS: ", results$dms)) %>%
      officer::body_add_par(paste0("WebAPI version: ", results$webAPIversion)) %>%
      officer::body_add_par(" ")

    doc<-doc %>%
      officer::body_add_par(value = "Vocabulary Query Performance", style = pkg.env$styles$heading2) %>%
      officer::body_add_par(paste0("The number of 'Maps To' relations is equal to ", results$performanceResults$performanceBenchmark$result,
                                   ". This query was executed in ",sprintf("%.2f", results$performanceResults$performanceBenchmark$duration)," secs"))

    doc<-doc %>%
      officer::body_add_par(value = "Achilles Query Performance", style = pkg.env$styles$heading2) %>%
      officer::body_add_par("Execution time of queries of the Achilles R-Package", style = pkg.env$styles$tableCaption)

    if (!is.null(results$performanceResults$achillesTiming$result)) {
      doc<-doc %>%
        my_body_add_table(value =results$performanceResults$achillesTiming$result, style = pkg.env$styles$table) %>%
        officer::body_add_par(paste("Query executed in ",sprintf("%.2f", results$performanceResults$achillesTiming$duration)," secs"), style = pkg.env$styles$footnote)
    } else {
      doc<-doc %>%
        officer::body_add_par("Query did not return results ", style = pkg.env$styles$highlight)
    }
  } else {
    doc<-doc %>%
      officer::body_add_par("Performance checks have not been executed, runPerformanceChecks = FALSE?", style = pkg.env$styles$highlight)
  }

  ## save the doc as a word file
  outputFile <- file.path(outputFolder, paste0("CdmOnboarding-", results$databaseId, ".docx"))
  writeLines(paste("Saving doc to", outputFile))
  print(doc, target = outputFile)
}


