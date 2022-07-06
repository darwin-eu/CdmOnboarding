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


#' Generates the Results Document
#'
#' @description
#' \code{generateResultsDocument} creates a word document with results based on a template
#' @param results             Results object from \code{cdmOnboarding}
#' @param outputFolder        Folder to store the results
#' @param authors             List of author names to be added in the document
#' @param databaseDescription Description of the database
#' @param databaseName        Name of the database
#' @param databaseId          Id of the database
#' @param smallCellCount      Date with less than this number of patients are removed
#' @param silent              Flag to not create output in the terminal (default = FALSE)
#' @export
generateResultsDocument<- function(results, outputFolder, authors = "Author Names", databaseDescription, databaseName, databaseId, smallCellCount, silent=FALSE) {
  docTemplate <- system.file("templates", "Template-DarwinEU.docx", package="CdmOnboarding")
  logo <- system.file("templates", "img", "darwin-logo.jpg", package="CdmOnboarding")

  ## open a new doc from the doctemplate
  doc<-officer::read_docx(path = docTemplate)
  ## add Title Page
  doc<- doc %>%
    officer::body_add_img(logo,width=6.10,height=1.59, style = "Title") %>%
    officer::body_add_par(value = paste0("CDM Onboarding report for the ",databaseName," database"), style = "Title") %>%
    #body_add_par(value = "Note", style = "heading 1") %>%
    officer::body_add_par(value = paste0("Package Version: ", packageVersion("CdmOnboarding")), style = "Heading centred (Agency)") %>%
    officer::body_add_par(value = paste0("Date: ", date()), style = "Heading centred (Agency)") %>%
    officer::body_add_par(value = paste0("Authors: ", authors), style = "Heading centred (Agency)") %>%
    officer::body_add_break()

  ## add Table of content
  doc<-doc %>%
    officer::body_add_par(value = "Table of content", style = "heading 1") %>%
    officer::body_add_toc(level = 2) %>%
    officer::body_add_break()

  ## add Concept counts
  if (!is.null(results$dataTablesResults)) {
    df_t1 <- results$dataTablesResults$dataTablesCounts$result
    doc<-doc %>%
      officer::body_add_par(value = "Record counts data tables", style = "heading 2") %>%
      officer::body_add_par("Table 1. Shows the number of records in all clinical data tables") %>%
      my_body_add_table(value = df_t1[order(df_t1$COUNT, decreasing=TRUE),], style = "Normal Table") %>%
      officer::body_add_par(" ") %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", results$dataTablesResults$dataTablesCounts$duration),"secs"))

    plot <- recordsCountPlot(as.data.frame(results$dataTablesResults$totalRecords$result))
    doc<-doc %>% officer::body_add_break() %>%
      officer::body_add_par(value = "Data density plots", style = "heading 2") %>%
      officer::body_add_gg(plot, height=4) %>%
      officer::body_add_par("Figure 1. Total record count over time per data domain")

    plot <- recordsCountPlot(as.data.frame(results$dataTablesResults$recordsPerPerson$result))
    doc<-doc %>%
      officer::body_add_gg(plot, height=4) %>%
      officer::body_add_par("Figure 2. Number of records per person over time per data domain")

    colnames(results$dataTablesResults$conceptsPerPerson$result) <- c("Domain", "Min", "P10", "P25", "MEDIAN", "P75", "P90", "Max")
    doc<-doc %>% officer::body_add_break() %>%
      officer::body_add_par(value = "Distinct concepts per person", style = "heading 2") %>%
      officer::body_add_par("Table 2. Shows the number of distinct concepts per person for all data domains") %>%
      my_body_add_table(value = results$dataTablesResults$conceptsPerPerson$result, style = "Normal Table") %>%
      officer::body_add_par(" ")

  }


  ## Vocabulary checks section
  doc<-doc %>%
    officer::body_add_par(value = "Vocabulary Mapping", style = "heading 1")

  vocabResults <-results$vocabularyResults
  if (!is.null(vocabResults)) {
    #vocabularies table
    doc<-doc %>%
      officer::body_add_par(value = "Vocabularies", style = "heading 2") %>%
      officer::body_add_par(paste0("Vocabulary version: ",results$vocabularyResults$version)) %>%
      officer::body_add_par("Table 3. The vocabularies available in the CDM with concept count. Note that this does not reflect which concepts are actually used in the clinical CDM tables. S=Standard, C=Classification and '-'=Non-standard") %>%
      my_body_add_table(value = vocabResults$conceptCounts$result, style = "Normal Table") %>%
      officer::body_add_par(" ") %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$conceptCounts$duration),"secs"))

    ## add vocabulary table counts

    doc <- doc %>%
      officer::body_add_par(value = "Table counts", style = "heading 2") %>%
      officer::body_add_par("Table 4. Shows the number of records in all vocabulary tables") %>%
      my_body_add_table(value = vocabResults$vocabularyCounts$result, style = "Normal Table") %>%
      officer::body_add_par(" ") %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$vocabularyCounts$duration),"secs"))

    ## add Mapping Completeness
    vocabResults$mappingCompleteness$result$'%Codes Mapped' <- prettyHr(vocabResults$mappingCompleteness$result$'%Codes Mapped')
    vocabResults$mappingCompleteness$result$'%Records Mapped' <- prettyHr(vocabResults$mappingCompleteness$result$'%Records Mapped')

    doc<-doc %>%
      officer::body_add_par(value = "Mapping Completeness", style = "heading 2") %>%
      officer::body_add_par("Table 5. Shows the percentage of codes that are mapped to the standardized vocabularies as well as the percentage of records.") %>%
      my_body_add_table(value = vocabResults$mappingCompleteness$result, style = "Normal Table", alignment = c('l', rep('r',6))) %>%
      officer::body_add_par(" ") %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$mappingCompleteness$duration),"secs")) %>%
      officer::body_add_break()

    ## add Drug Level Mappings
    doc<-doc %>%
      officer::body_add_par(value = "Drug Mappings", style = "heading 2") %>%
      officer::body_add_par("Table 6. The level of the drug mappings") %>%
      my_body_add_table(value = vocabResults$drugMapping$result, style = "Normal Table") %>%
      officer::body_add_par(" ") %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$drugMapping$duration),"secs"))

    ## add Top 25 missing mappings
    doc<-doc %>%
      officer::body_add_par(value = "Unmapped Codes", style = "heading 2")
    my_unmapped_section(doc, vocabResults$unmappedDrugs, 7, "drugs", smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedConditions, 8, "conditions", smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedMeasurements, 9, "measurements", smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedObservations, 10, "observations",smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedProcedures, 11, "procedures", smallCellCount)
    my_unmapped_section(doc, vocabResults$unmappedDevices, 12, "devices", smallCellCount)

    ## add top 25 mapped codes
    doc<-doc %>%
      officer::body_add_par(value = "Mapped Codes", style = "heading 2")
    my_mapped_section(doc, vocabResults$mappedDrugs, 13, "drugs", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedConditions, 14, "conditions", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedMeasurements, 15, "measurements", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedObservations, 16, "observations", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedProcedures, 17, "procedures", smallCellCount)
    my_mapped_section(doc, vocabResults$mappedDevices, 18, "devices", smallCellCount)

    ## add source_to_concept_map breakdown
    doc<-doc %>%
      officer::body_add_par(value = "Source to concept map", style = "heading 2") %>%
      officer::body_add_par("Table 19. Source to concept map breakdown") %>%
      my_body_add_table(value = vocabResults$sourceConceptFrequency$result, style = "Normal Table") %>%
      officer::body_add_par(" ") %>%
      officer::body_add_par(paste("Query executed in ",sprintf("%.2f", vocabResults$sourceConceptFrequency$duration),"secs")) %>%
      officer::body_add_par("Note that the full source_to_concept_map table is added in the results.zip", style="Drafting Notes (Agency)")

  } else {
    doc<-doc %>%
    officer::body_add_par("Vocabulary checks have not been executed, runVocabularyChecks = FALSE?", style="Drafting Notes (Agency)") %>%
    officer::body_add_break()
  }

  doc<-doc %>%
    officer::body_add_par(value = "Technical Infrastructure", style = "heading 1")

  if (!is.null(results$dataTablesResults)) {
    # cdm source
    t_cdmSource <- data.table::transpose(results$cdmSource)
    colnames(t_cdmSource) <- rownames(results$cdmSource)
    field <- colnames(results$cdmSource)
    t_cdmSource <- cbind(field, t_cdmSource)
    doc<-doc %>%
      officer::body_add_par(value = "CDM Source Table", style = "heading 2") %>%
      officer::body_add_par("Table 20. cdm_source table content") %>%
      my_body_add_table(value =t_cdmSource, style = "Normal Table")
  }

  if (!is.null(results$performanceResults)) {
    #installed packages
    doc<-doc %>%
      officer::body_add_par(value = "HADES packages", style = "heading 2") %>%
      officer::body_add_par("Table 21. Versions of all installed HADES R packages") %>%
      my_body_add_table(value = results$hadesPackageVersions, style = "Normal Table")

    if (results$missingPackage=="") {
      doc<-doc %>%
      officer::body_add_par("All HADES packages were available")
    } else {
      doc<-doc %>%
      officer::body_add_par(paste0("Missing HADES packages: ",results$missingPackages))
    }

    #system detail
    doc<-doc %>%
      officer::body_add_par(value = "System Information", style = "heading 2") %>%
      officer::body_add_par(paste0("Installed R version: ", results$sys_details$r_version$version.string)) %>%
      officer::body_add_par(paste0("System CPU vendor: ", results$sys_details$cpu$vendor_id, collapse =", ")) %>%
      officer::body_add_par(paste0("System CPU model: ", results$sys_details$cpu$model_name, collapse =", ")) %>%
      officer::body_add_par(paste0("System CPU number of cores: ", results$sys_details$cpu$no_of_cores, collapse =", ")) %>%
      officer::body_add_par(paste0("System RAM: ", prettyunits::pretty_bytes(as.numeric(results$sys_details$ram, collapse =", ")))) %>%
      officer::body_add_par(paste0("DBMS: ", results$dms)) %>%
      officer::body_add_par(paste0("WebAPI version: ", results$webAPIversion)) %>%
      officer::body_add_par(" ")


    doc<-doc %>%
      officer::body_add_par(value = "Vocabulary Query Performance", style = "heading 2") %>%
      officer::body_add_par(paste0("The number of 'Maps To' relations is equal to ", results$performanceResults$performanceBenchmark$result,
                                   ". This query was executed in ",sprintf("%.2f", results$performanceResults$performanceBenchmark$duration)," secs"))

    doc<-doc %>%
      officer::body_add_par(value = "Achilles Query Performance", style = "heading 2") %>%
      officer::body_add_par("Table 22. Execution time of queries of the Achilles R-Package")

    if (!is.null(results$performanceResults$achillesTiming$result)) {
      doc<-doc %>%
        my_body_add_table(value =results$performanceResults$achillesTiming$result, style = "Normal Table") %>%
        officer::body_add_par(" ") %>%
        officer::body_add_par(paste("Query executed in ",sprintf("%.2f", results$performanceResults$achillesTiming$duration)," secs"))
    } else {
      doc<-doc %>%
        officer::body_add_par("Query did not return results ", style="Drafting Notes (Agency)")
    }
  } else {
    doc<-doc %>%
      officer::body_add_par("Performance checks have not been executed, runPerformanceChecks = FALSE?", style="Drafting Notes (Agency)") %>%
      body_add_break()
  }

  ## save the doc as a word file
  outputFile <- file.path(outputFolder, paste0("CdmOnboarding-results-", results$databaseId, ".docx"))
  writeLines(paste("Saving doc to", outputFile))
  print(doc, target = outputFile)
}



