# @file GenerateResultsDocument
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
#' @param silent              Flag to not create output in the terminal (default = FALSE)
#' @export
generateResultsDocument <- function(results, outputFolder, authors, silent = FALSE) {
  docTemplate <- system.file("templates", "Template-CdmOnboarding.docx", package = "CdmOnboarding")

  # open a new doc from the doctemplate
  doc <- officer::read_docx(path = docTemplate)

  # add Title Page
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
  df <- data.frame(rbind(
    c("CdmOnboarding package version", paste0(
      as.character(packageVersion("CdmOnboarding")),
      if (results$runWithOptimizedQueries) ' (performance optimized=TRUE)' else ''
    )),
    c("Database", results$dms),
    c("CDM version", results$cdmSource$CDM_VERSION),
    c("Execution date", results$executionDate),
    c("Execution duration", prettyunits::pretty_sec(results$executionDuration)),
    c("Achilles version", results$achillesMetadata$ACHILLES_VERSION),
    c("Achilles execution date", results$achillesMetadata$ACHILLES_EXECUTION_DATE)
  ))
  names(df) <- c('Detail', 'Value')
  doc <- doc %>%
    officer::body_add_par("Execution details", style = pkg.env$styles$heading1) %>%
    my_body_add_table(df) %>%
    # Explanation of symbols
    officer::body_add_par(
      sprintf(
        "Symbols used in table/figure captions: %s=Computed directly from OMOP CDM data, %s=Computed from Achilles results, %s=Estimated from system tables.", # nolint
        pkg.env$sources$cdm,
        pkg.env$sources$achilles,
        pkg.env$sources$system
      )
    )

  # CDM Source
  t_cdmSource <- data.table::transpose(results$cdmSource)
  colnames(t_cdmSource) <- c('Values')
  field <- colnames(results$cdmSource)
  t_cdmSource <- cbind(field, t_cdmSource)
  doc <- doc %>%
    officer::body_add_par("CDM Source Table", style = pkg.env$styles$heading2) %>%
    my_table_caption("Content of the OMOP cdm_source table", sourceSymbol = pkg.env$sources$cdm) %>%
    my_body_add_table(t_cdmSource) %>%
    officer::body_add_break()

  counts_optimized <- results$runWithOptimizedQueries && results$dms %in% c("postgresql", "sqlserver")

  df <- results$dataTablesResults
  if (!is.null(df)) {
    # Pre-compute counts
    personCount <- df$dataTablesCounts$result %>%
      dplyr::filter(TABLENAME == 'person') %>%
      pull(COUNT)
    deathCount <- df$dataTablesCounts$result %>%
      dplyr::filter(TABLENAME == 'death') %>%
      pull(COUNT)

    # Total records per table
    df$dataTablesCounts$result <- df$dataTablesCounts$result %>%
      arrange(desc(COUNT)) %>%
      mutate(
        Table = TABLENAME,
        `#Records` = COUNT,
        `#Persons` = N_PERSONS,
        `%Persons` = prettyPc(N_PERSONS / personCount * 100),
        .keep = "none"  # do not display other columns
      )

    doc <- doc %>%
      officer::body_add_par("Clinical data", style = pkg.env$styles$heading1) %>%
      officer::body_add_par("Record counts per OMOP CDM table", style = pkg.env$styles$heading2) %>%
      my_table_caption("The number of records in all clinical data tables", sourceSymbol = if (counts_optimized) pkg.env$sources$system else pkg.env$sources$cdm) %>%
      my_body_add_table_runtime(df$dataTablesCounts, alignment = c('l', rep('r', 3)))

    doc <- doc %>%
      officer::body_add_break() %>%
      officer::body_add_par("Data density plots", style = pkg.env$styles$heading2)

    totalRecordsPlot <- .recordsCountPlot(as.data.frame(df$totalRecords$result), log_y_axis = TRUE)
    doc <- doc %>%
      officer::body_add_gg(totalRecordsPlot, height = 4) %>%
      my_figure_caption("Total record count over time per OMOP data domain.", sourceSymbol = pkg.env$sources$achilles)

    recordsPerPersonPlot <- .recordsCountPlot(as.data.frame(df$recordsPerPerson$result), log_y_axis = TRUE)
    doc <- doc %>%
      officer::body_add_gg(recordsPerPersonPlot, height = 4) %>%
      my_figure_caption("Number of records per person over time per OMOP data domain.", sourceSymbol = pkg.env$sources$achilles)

    # Mortality
    overallMortality <- round(deathCount / personCount * 100, 2)

    if (deathCount > 0) {
      totalDeath <- df$totalRecords$result %>%
        dplyr::filter(SERIES_NAME %in% 'Death')
      totalDeathPlot <- .recordsCountPlot(as.data.frame(totalDeath), hide_legend = TRUE)
      doc <- doc %>%
        officer::body_add_gg(totalDeathPlot, height = 4)
    } else {
      doc <- doc %>%
        officer::body_add_par("No death records found.", style = pkg.env$styles$highlight)
    }
    doc <- doc %>%
      my_figure_caption(
        sprintf(
          "Number of deaths in each month. Overall mortality: %s%%.",
          overallMortality
        ),
        sourceSymbol = pkg.env$sources$achilles
      )

    doc <- doc %>%
      officer::body_add_break() %>%
      officer::body_add_par("Distinct concepts per person", style = pkg.env$styles$heading2) %>%
      my_table_caption("The number of distinct concepts per person per OMOP data domains. Only persons with at least one record in that domain are included in the calculation.", sourceSymbol = pkg.env$sources$achilles) %>% #nolint
      my_body_add_table_runtime(df$conceptsPerPerson)

    # Observation Period
    plot <- .recordsCountPlot(as.data.frame(df$observedByMonth$result), hide_legend = TRUE)
    n_active_persons <- df$activePersons$result # dataframe of length one. Missing column name in some cases.
    active_index_date <- dplyr::coalesce(results$cdmSource$SOURCE_RELEASE_DATE, results$cdmSource$CDM_RELEASE_DATE)
    doc <- doc %>%
      officer::body_add_par("") %>%
      officer::body_add_par("Observation Period", style = pkg.env$styles$heading2) %>%
      officer::body_add_gg(plot, height = 4) %>%
      my_figure_caption(
        sprintf(
          "Persons with continuous observation by month.%s In the last 6 months (before %s), there are %s persons with an active observation period.%s",
          pkg.env$sources$achilles,
          active_index_date,
          prettyHr(n_active_persons),
          pkg.env$sources$cdm
        ),
        sourceSymbol = ''  # already in caption text
      ) %>%
      officer::body_add_par("")

    # Length of first observation period
    df$observationPeriodLength$result <- round(df$observationPeriodLength$result / 365, 1)
    df$observationPeriodLength$result <- df$observationPeriodLength$result %>%
      mutate(
        AVG = AVG_VALUE,
        STDEV = STDEV_VALUE,
        MIN = MIN_VALUE,
        P10 = P10_VALUE,
        P25 = P25_VALUE,
        MEDIAN = MEDIAN_VALUE,
        P75 = P75_VALUE,
        P90 = P90_VALUE,
        MAX = MAX_VALUE,
        .keep = "none"  # do not display other columns
      )

    doc <- doc %>%
      my_table_caption("Length of first observation period (years).", sourceSymbol = pkg.env$sources$achilles) %>%
      my_body_add_table_runtime(df$observationPeriodLength)

    # Combine Observation Periods per Person and overlap in one table
    if (!is.null(df$observationPeriodsPerPerson$result)) {
      obsPeriodStats <- df$observationPeriodsPerPerson$result %>%
        mutate(
          Field = sprintf("Persons with %s observation period(s)", N_OBSERVATION_PERIODS),
          Value = N_PERSONS,
          `%Persons` = N_PERSONS / personCount * 100,
          .keep = "none"  # do not display other columns
        )
    } else {
      obsPeriodStats <- data.frame(
        Field = "Persons with observation period(s)",
        Value = NA,
        `%Persons` = NA,
        check.names = FALSE  # To allow `%Persons`
      )
    }

    obsPeriodStats <- rbind(
      obsPeriodStats,
      data.frame(
        Field = c("Persons with overlapping observation periods", "Number of overlapping observation periods"),
        Value = c(
          nrow(df$observationPeriodOverlap),
          sum(df$observationPeriodOverlap$result$N_OVERLAPPING_PAIRS)
        ),
        `%Persons` = c(
          nrow(df$observationPeriodOverlap) / personCount * 100,
          NA
        ),
        check.names = FALSE
      )
    )

    doc <- doc %>%
      my_table_caption(
        sprintf("Number of observation periods per person %s and overlapping observation periods %s.", pkg.env$sources$achilles, pkg.env$sources$cdm),
        sourceSymbol = NULL  # already in caption text
      ) %>%
      my_body_add_table(obsPeriodStats) %>%
      officer::body_add_par(
        sprintf("Queries executed in %.2f seconds and %.2f seconds",
          df$observationPeriodsPerPerson$duration,
          df$observationPeriodOverlap$duration
        ), style = pkg.env$styles$footnote)

    df$dateRangeByTypeConcept$result <- df$dateRangeByTypeConcept$result %>%
      mutate(
        `Domain` = DOMAIN,
        `N` = COUNT_VALUE,
        `Type` = sprintf("%s (%s)", TYPE_CONCEPT_NAME, TYPE_STANDARD_CONCEPT),
        `Start date [Min, Max]` = sprintf(
          "[%s, %s]", 
          substr(FIRST_START_DATE, 1, 7), 
          substr(LAST_START_DATE, 1, 7)
        ),
        `End date [Min, Max]` = sprintf(
          "[%s, %s]",
          substr(FIRST_END_DATE, 1, 7),
          substr(LAST_END_DATE, 1, 7)
        ),
        .keep = "none"  # do not display other columns
      ) %>%
      arrange(Domain)
    doc <- doc %>%
      officer::body_add_par("Date Range", style = pkg.env$styles$heading2) %>%
      my_table_caption("Minimum and maximum event start date in each table, within an observation period and at least 5 records. Floored to the nearest month.", sourceSymbol = pkg.env$sources$achilles) %>% #nolint
      my_body_add_table_runtime(
        df$dateRangeByTypeConcept,
        alignment = c('l', 'l', rep('r', ncol(df$dateRangeByTypeConcept$result) - 2))
      )

    df$visitLength$result <- df$visitLength$result %>%
      mutate(
        Domain = DOMAIN,
        `Concept Name` = CONCEPT_NAME,
        AVG = round(AVG_VALUE, 1),
        STDEV = round(STDEV_VALUE, 1),
        MIN = MIN_VALUE,
        P10 = P10_VALUE,
        P25 = P25_VALUE,
        MEDIAN = MEDIAN_VALUE,
        P75 = P75_VALUE,
        P90 = P90_VALUE,
        MAX = MAX_VALUE,
        .keep = "none"  # do not display other columns
      ) %>%
      arrange(Domain)

    doc <- doc %>%
      my_table_caption("Length of stay by visit concept. The length should be interpreted as number of nights, meaning a length of 0 is a same-day visit.", sourceSymbol = pkg.env$sources$achilles) %>%
      my_body_add_table_runtime(df$visitLength)

    # Day of the week and month
    combinedPlot <- cowplot::ggdraw()
    if (!is.null(df$dayOfTheWeek$result)) {
      dayOfTheWeekPlot <- .heatMapPlot(df$dayOfTheWeek$result, "DAY_OF_THE_WEEK")
      combinedPlot <- combinedPlot +
        cowplot::draw_plot(dayOfTheWeekPlot, x = 0, y = .48, width = .5, height = .5) +
        cowplot::draw_plot_label("Day of the Week", x = .15, y = .99, size = 15)
    } else {
      doc <- doc %>%
        officer::body_add_par("No Day of the Week results.")
    }

    if (!is.null(df$dayOfTheMonth$result)) {
      dayOfTheMonthPlot <- .heatMapPlot(df$dayOfTheMonth$result, "DAY_OF_THE_MONTH")
      combinedPlot <- combinedPlot +
        cowplot::draw_plot(dayOfTheMonthPlot, x = .5, y = 0, width = .5, height = 1) +
        cowplot::draw_plot_label("Day of the Month", x = .65, y = .98, size = 15)
    } else {
      doc <- doc %>%
        officer::body_add_par("No Day of the Month results.")
    }

    doc <- doc %>%
      officer::body_add_gg(combinedPlot, scale = .5) %>%
      my_figure_caption("Day of the Week and Day of the Month distribution of event start dates after 1900-01-01 per domain. 1 = Monday ... 7 = Sunday.", sourceSymbol = pkg.env$sources$cdm) %>% #nolint
      officer::body_add_par(
        sprintf("Queries executed in %.2f seconds and %.2f seconds",
          df$dayOfTheWeek$duration,
          df$dayOfTheMonth$duration
        ),
        style = pkg.env$styles$footnote
      )

    # Day, Month, Year of Birth
    doc <- doc %>%
        officer::body_add_par("Day, Month, Year of Birth", style = pkg.env$styles$heading2)
    if (!is.null(df$dayMonthYearOfBirth$result)) {
        df$dayMonthYearOfBirth$result <- df$dayMonthYearOfBirth$result %>%
          arrange(desc(VARIABLE)) %>% # Year, Month, Day
          mutate(
            ` ` = VARIABLE,
            `%Missing` = prettyPc(P_MISSING),
            MIN = MIN_VALUE,
            P10 = P10_VALUE,
            P25 = P25_VALUE,
            MEDIAN = MEDIAN_VALUE,
            P75 = P75_VALUE,
            P90 = P90_VALUE,
            MAX = MAX_VALUE,
            .keep = "none"  # do not display other columns
          )
       doc <- doc %>%
        my_table_caption("Distribution of day, month and year of birth of persons.", sourceSymbol = pkg.env$sources$cdm) %>%
        my_body_add_table_runtime(
          df$dayMonthYearOfBirth,
          auto_format = FALSE,
          alignment = c('l', rep('r', ncol(df$dayMonthYearOfBirth$result) - 1))
        )
    } else {
      doc <- doc %>%
        my_table_caption("No Day, Month, Year of Birth results.", sourceSymbol = pkg.env$sources$cdm)
    }

    doc <- doc %>% officer::body_add_break()
  }

  ## Vocabulary checks section
  doc <- doc %>%
    officer::body_add_par("Vocabulary mappings", style = pkg.env$styles$heading1)

  vocabResults <- results$vocabularyResults
  if (!is.null(vocabResults)) {
    doc <- doc %>%
      officer::body_add_par(
        sprintf(
          "Vocabulary version: %s",
          results$vocabularyResults$version
        )
      ) %>%
      officer::body_add_par(
        sprintf(
          "Pre-processing query executed in %.2f seconds",
          results$vocabularyResults$mappingTempTableCreation$duration
        ),
        style = pkg.env$styles$footnote
      )

    # Mapping Completeness
    vocabResults$mappingCompleteness$result <- vocabResults$mappingCompleteness$result %>%
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
    doc <- doc %>%
      officer::body_add_par("Mapping Completeness", style = pkg.env$styles$heading2) %>%
      my_table_caption(
        paste(
          "The number and percentage of codes and records that are mapped to an OMOP concept (not 0 and <2B)."
          , "Note: for one-to-many mappings, the source codes will be counted multiple times so the reported total source codes"
          , "could be bigger than actual number of unique source codes."
        ),
        sourceSymbol = pkg.env$sources$cdm
      ) %>%
      my_body_add_table_runtime(vocabResults$mappingCompleteness, alignment = c('l', rep('r', 6)))

    # Drug Level Mappings
    vocabResults$drugMapping$result <- vocabResults$drugMapping$result %>%
      arrange(desc(N_RECORDS)) %>%
      mutate(
        Class = CLASS,
        `#Records` = N_RECORDS,
        `#Patients` = N_PATIENTS,
        `#Codes` = N_SOURCE_CODES,
        `%Records` = prettyPc(P_RECORDS),
        .keep = "none"  # do not display other columns
      )
    doc <- doc %>%
      officer::body_add_par("Drug Mappings", style = pkg.env$styles$heading2) %>%
      my_table_caption("The level of the drug mappings", sourceSymbol = pkg.env$sources$cdm) %>%
      my_body_add_table_runtime(vocabResults$drugMapping, alignment =  c('l', rep('r', 4)))

    # Top 25 unmapped codes
    doc <- doc %>%
      officer::body_add_par("Unmapped Codes", style = pkg.env$styles$heading2) %>%
      my_unmapped_section(vocabResults$unmappedDrugs, "drugs", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedConditions, "conditions", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedMeasurements, "measurements", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedObservations, "observations", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedProcedures, "procedures", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedDevices, "devices", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedVisits, "visits", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedVisitDetails, "visit details", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedUnitsMeas, "measurement units", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedUnitsObs, "observation units", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedValuesMeas, "measurement values", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedValuesObs, "observation values", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedDrugRoute, "drug route", results$smallCellCount) %>%
      my_unmapped_section(vocabResults$unmappedSpecialty, "specialty", results$smallCellCount)

    # Top 25 mapped concepts
    doc <- doc %>%
      officer::body_add_par("Mapped Codes", style = pkg.env$styles$heading2) %>%
      my_mapped_section(vocabResults$mappedDrugs, "drugs", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedConditions, "conditions", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedMeasurements, "measurements", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedObservations, "observations", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedProcedures, "procedures", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedDevices, "devices", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedVisits, "visits", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedVisitDetails, "visit details", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedUnitsMeas, "measurement units", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedUnitsObs, "observation units", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedValuesMeas, "measurement values", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedValuesObs, "observation values", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedDrugRoute, "drug route", results$smallCellCount) %>%
      my_mapped_section(vocabResults$mappedSpecialty, "specialty", results$smallCellCount)

    ## add source_to_concept_map breakdown
    doc <- doc %>%
      officer::body_add_par("Source to concept map", style = pkg.env$styles$heading2) %>%
      my_table_caption("Source to concept map breakdown", sourceSymbol = pkg.env$sources$cdm) %>%
      my_body_add_table_runtime(vocabResults$sourceConceptFrequency) %>%
      officer::body_add_par("") %>%
      officer::body_add_par("Note that the full source_to_concept_map table is added in the results rds", style = pkg.env$styles$highlight)

  } else {
    doc <- doc %>%
      officer::body_add_par("Vocabulary checks have not been executed, runVocabularyChecks = FALSE?", style = pkg.env$styles$highlight) %>%
      officer::body_add_break()
  }

  doc <- doc %>%
    officer::body_add_par("Data Quality Dashboard", style = pkg.env$styles$heading1)

  dqdResults <- results$dqdResults
  if (!is.null(dqdResults)) {
    dqdOverview <- with(
      dqdResults$overview,
      data.frame(
        Category = c("Plausibility", "Conformance", "Completeness", "Total"),
        Pass = c(countPassedPlausibility, countPassedConformance, countPassedCompleteness, countPassed),
        Fail = c(countFailedPlausibility, countFailedConformance, countFailedCompleteness, countOverallFailed),
        Total = c(countTotalPlausibility, countTotalConformance, countTotalCompleteness, countTotal)
      )
    )
    dqdOverview$`%Pass` <- prettyPc(dqdOverview$Pass / dqdOverview$Total * 100)

    doc <- doc %>%
      officer::body_add_par(sprintf(
        "DataQualityDashboard Version: %s",
        dqdResults$version[1]
      )) %>%
      officer::body_add_par(sprintf(
        "DataQualityDashboard executed at %s in %s.",
        dqdResults$startTimestamp,
        dqdResults$executionTime
      )) %>%
      my_table_caption("Number of passed, failed and total DQD checks per category. For DQD v2, the checks with status 'NA' are not included.", sourceSymbol = "") %>%
      my_body_add_table(dqdOverview, first_column = TRUE, alignment = c('l', rep('r', 4)), last_row = TRUE)
  } else {
    doc <- doc %>%
      officer::body_add_par("DataQualityDashboard results have not been provided.", style = pkg.env$styles$highlight)
  }

  doc <- doc %>%
    officer::body_end_section_portrait() %>%
    officer::body_add_par("Drug Exposure Diagnostics", style = pkg.env$styles$heading1)

  dedResults <- results$drugExposureDiagnostics
  if (!is.null(dedResults)) {
    # Backwards compatibility with 2.1 where dedResults was not wrapped in result object + duration.
    if (!('result' %in% names(dedResults))) {
      dedResults <- list(result = dedResults, duration = NULL)
    }

    dedResults$result <- dedResults$result %>%
      mutate(
          `Ingredient` = ingredient,
          `Concept ID` = ingredient_concept_id,
          `#` = n_records,
          `Type (n,%)` = proportion_of_records_by_drug_type,
          `Route (n,%)` = proportion_of_records_by_route_type,
          `Dose Form present n (%)` = proportion_of_records_with_dose_form,
          `Fixed amount dose form n (%)` = proportion_of_records_missing_denominator_unit_concept_id,
          `Amount distrib. [null or missing]` = median_amount_value_q05_q95,
          `Quantity distrib. [null or missing]` = median_quantity_q05_q95,
          `Exposure days distrib. [null or missing]` = median_drug_exposure_days_q05_q95,
          `Neg. Days n (%)` = proportion_of_records_with_negative_drug_exposure_days,
          .keep = "none"  # do not display other columns
        )

    doc <- doc %>%
      my_table_caption(
        paste(
          "Drug Exposure Diagnostics results for selected ingredients.",
          "Executed with minCellCount = 5, sample = 1e+06, earliestStartDate = 2010-01-01.",
          "# = Number of records.",
          "Type (n,%) = Frequency and percentage of available drug types.",
          "Route (n,%) = Frequency and percentage of available routes.",
          "Dose Form present n (%) = Frequency and percentage with dose form present.",
          "Fixed amount dose form n (%) = Frequency and percentage of missing denominator unit concept id.",
          "Amount distrib. [null or missing] = Distribution of amount (median q05-q95), frequency and percentage of null or missing amount.",
          "Quantity distrib. [null or missing] = Distribution of quantity (median q05-q95), frequency and percentage of null or missing quantity.",
          "Exposure days distrib. [null or missing] = Distribution of exposure days (median q05-q95), frequency and percentage of null days_supply or missing exposure dates.",
          "Neg. Days n (%) = Frequency and percentage of negative exposure days."),
        sourceSymbol = pkg.env$sources$cdm
      ) %>%
      my_body_add_table_runtime(dedResults)
  } else {
    doc <- doc %>%
      officer::body_add_par("Drug Exposure Diagnostics results are missing.", style = pkg.env$styles$highlight)
  }

  doc <- doc %>% officer::body_end_section_landscape()

  doc <- doc %>%
    officer::body_add_par("Technical Infrastructure", style = pkg.env$styles$heading1)

  df_pr <- results$performanceResults
  if (!is.null(df_pr)) {
    # Installed packages
    allPackages <- data.frame(
      Package = c(getHADESpackages(), getDARWINpackages()),
      Version = "",
      Organisation = c(rep("OHDSI HADES", length(getHADESpackages())), rep("DARWIN EU\u00AE", length(getDARWINpackages())))
    )

    packageVersions <- dplyr::union(df_pr$hadesPackageVersions, df_pr$darwinPackageVersions) %>%
      dplyr::full_join(allPackages, by = c("Package")) %>%
      dplyr::mutate(
        Version = dplyr::coalesce(Version.x, "Not installed")
      ) %>%
      # Sorting on LibPath to get packages in same environment together (if multiple versions of the same package installed due to renvs)
      dplyr::arrange(Organisation, LibPath, Package) %>%
      dplyr::select(Organisation, Package, Version)

    doc <- doc %>%
      officer::body_add_par("R packages", style = pkg.env$styles$heading2) %>%
      my_table_caption(
        paste(
          "Versions of all installed R packages from DARWIN EU\u00AE and the OHDSI Health Analytics Data-to-Evidence Suite (HADES).",
          "Packages can be installed from CRAN (install.packages(\"<package_name>\")) or Github (remotes::install_github(\"<organisation>/<package>\"))"
        ),
        sourceSymbol = pkg.env$sources$system
      ) %>%
      my_body_add_table(packageVersions)

    #system detail
    doc <- doc %>%
      officer::body_add_par("System Information", style = pkg.env$styles$heading2) %>%
      officer::body_add_par(paste0("Installed R version: ", df_pr$sys_details$r_version$version.string)) %>%
      officer::body_add_par(paste0("System CPU vendor: ", df_pr$sys_details$cpu$vendor_id, collapse = ", ")) %>%
      officer::body_add_par(paste0("System CPU model: ", df_pr$sys_details$cpu$model_name, collapse = ", ")) %>%
      officer::body_add_par(paste0("System CPU number of cores: ", df_pr$sys_details$cpu$no_of_cores, collapse = ", ")) %>%
      officer::body_add_par(paste0("System RAM: ", prettyunits::pretty_bytes(as.numeric(df_pr$sys_details$ram, collapse = ", ")))) %>%
      officer::body_add_par(paste0("DBMS: ", df_pr$dmsVersion)) %>%
      officer::body_add_par(paste0("WebAPI version: ", results$webAPIversion)) %>%
      officer::body_add_par("")

    doc <- doc %>%
      officer::body_add_par("Vocabulary Query Performance", style = pkg.env$styles$heading2)
    if (!is.null(df_pr$performanceBenchmark$result)) {
      n_relations <- df_pr$performanceBenchmark$result
      benchmark_query_time <- df_pr$performanceBenchmark$duration
      doc <- doc %>%
        officer::body_add_par(sprintf(
          "The number of 'Maps To' relations is equal to %s and queried in %.2f seconds (%g s/#).",
          prettyHr(n_relations),
          benchmark_query_time,
          benchmark_query_time / n_relations
        ))
    } else {
      doc <- doc %>%
        officer::body_add_par("Performance benchmark of the OMOP CDM tables could not be retrieved", style = pkg.env$styles$highlight)
    }

    doc <- doc %>%
      officer::body_add_par("Applied indexes", style = pkg.env$styles$heading2)
    if (!is.null(df_pr$appliedIndexes$result)) {
      expectedIndexes <- .getExpectedIndexes(results$cdmSource$CDM_VERSION)

      # filter to the OMOP CDM tables only
      if (!is.null(results$dataTablesResults$dataTablesCounts)) {
        omop_table_names <- results$dataTablesResults$dataTablesCounts$result[,1]
        df_pr$appliedIndexes$result <- df_pr$appliedIndexes$result %>%
          dplyr::filter(TABLENAME %in% omop_table_names)
      }

      missingIndexes <- setdiff(expectedIndexes, df_pr$appliedIndexes$result$INDEXNAME)
      additionalIndexes <- setdiff(df_pr$appliedIndexes$result$INDEXNAME, expectedIndexes)

      df_pr$appliedIndexes$result <- df_pr$appliedIndexes$result %>%
        dplyr::group_by(TABLENAME) %>%
        dplyr::summarize(
          INDEXNAMES = paste(INDEXNAME, collapse = ",")
        )

      doc <- doc %>%
        my_table_caption("The indexes applied on the OMOP CDM tables", sourceSymbol = pkg.env$sources$system) %>%
        my_body_add_table_runtime(df_pr$appliedIndexes)

      if (length(missingIndexes) > 0) {
        doc <- doc %>%
          officer::body_add_par("The following expected indexes are missing:") %>%
          officer::body_add_par("") %>%
          officer::body_add_par(paste(missingIndexes, collapse = ", "))
      } else {
        doc <- doc %>%
          officer::body_add_par("All expected indexes are present")
      }

      if (length(additionalIndexes) > 0) {
        doc <- doc %>%
          officer::body_add_par("") %>%
          officer::body_add_par("The following indexes have been applied additional to the expected indexes:") %>%
          officer::body_add_par("") %>%
          officer::body_add_par(paste(additionalIndexes, collapse = ", "))
      }
    } else {
      doc <- doc %>%
        officer::body_add_par("Applied indexes could not be retrieved", style = pkg.env$styles$highlight)
    }

    doc <- doc %>%
      officer::body_add_par("Achilles Query Performance", style = pkg.env$styles$heading2)

    # If Achilles version 1.7, then timings not well reported (introduced after 1.6.3, fixed in 1.7.1)
    if (results$achillesMetadata$ACHILLES_VERSION == '1.7') {
      doc <- doc %>% officer::body_add_par("WARNING: Achilles v1.7 was used. The run time is NOT standardised to one unit. Here, we assume they are all in seconds. This might not be accurate.") #nolint
    }

    arTimings <- results$performanceResults$achillesTiming$result
    if (!is.null(arTimings)) {
      arTimings <- arTimings %>% arrange(arTimings$ID)
      arTimings$ID <- as.character(arTimings$ID)
      if (utils::compareVersion(results$achillesMetadata$ACHILLES_VERSION, '1.6.3') < 1) {
        # version 1.6.3 contains unit, cannot convert to numeric.
        doc <- doc %>% my_table_caption("Execution time of Achilles analyses.", sourceSymbol = pkg.env$sources$achilles)
      } else {
        arTimings$DURATION <- as.numeric(arTimings$DURATION)
        # TODO: condition if no durations available
        # all(is.na(arTimings$DURATION))
        longestAnalysis <- arTimings %>% slice_max(DURATION, n = 1, na_rm = TRUE)
        doc <- doc %>%
          my_table_caption(
            sprintf(
              "Execution time of Achilles analyses. Total: %s. Median: %s. Longest duration: %s (analysis %s).",
              prettyunits::pretty_sec(sum(arTimings$DURATION, na.rm = TRUE)),
              prettyunits::pretty_sec(stats::median(arTimings$DURATION, na.rm = TRUE)),
              prettyunits::pretty_sec(longestAnalysis$DURATION),
              longestAnalysis$ID
            ),
            sourceSymbol = pkg.env$sources$achilles
          )
      }
      doc <- doc %>% my_body_add_table_runtime(results$performanceResults$achillesTiming)
    } else {
      doc <- doc %>%
        officer::body_add_par("Query did not return results", style = pkg.env$styles$highlight)
    }
  } else {
    doc <- doc %>%
      officer::body_add_par("Performance checks have not been executed, runPerformanceChecks = FALSE?", style = pkg.env$styles$highlight)
  }

  doc <- doc %>%
    officer::body_add_par("Appendix", style = pkg.env$styles$heading1)

  if (!is.null(vocabResults)) {
    # add vocabulary table counts
    vocabResults$vocabularyCounts$result <- vocabResults$vocabularyCounts$result %>%
      arrange(desc(COUNT))
    doc <- doc %>%
      officer::body_add_par("Vocabulary table counts", style = pkg.env$styles$heading2) %>%
      my_table_caption("The number of records in all vocabulary tables.", sourceSymbol = if (counts_optimized) pkg.env$sources$system else pkg.env$sources$cdm) %>% #nolint
      my_body_add_table_runtime(vocabResults$vocabularyCounts)

    # vocabularies table
    names(vocabResults$conceptCounts$result) <- c('ID', 'Name', 'Version', 'S', 'C', '-')
    doc <- doc %>%
      officer::body_add_par("Vocabulary concept counts", style = pkg.env$styles$heading2) %>%
      officer::body_add_par(sprintf("Vocabulary version: %s", results$vocabularyResults$version)) %>%
      my_table_caption("The vocabularies available in the CDM with concept count. Note that this does not reflect which concepts are actually used in the clinical CDM tables. S=Standard, C=Classification and '-'=Non-standard", sourceSymbol = pkg.env$sources$cdm) %>% #nolint
      my_body_add_table_runtime(vocabResults$conceptCounts)
  }

  ## save the doc as a word file
  outputFile <- file.path(outputFolder, sprintf("CdmOnboarding_%s_%s.docx", results$databaseId, format(Sys.time(), "%Y%m%d")))
  writeLines(paste("Saving doc to", outputFile))
  print(doc, target = outputFile)
}
