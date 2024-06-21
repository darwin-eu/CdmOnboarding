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

#' Generates the Data Tables section for the Results Document
#'
#' @param doc officer document object to add the section to
#' @param df Results object from \code{cdmOnboarding} dataTablesResults
#' @param optimized boolean indicating if the optimized queries were used
generateDataTablesSection <- function(doc, df, optimized) {
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
    officer::body_add_par("Record counts per OMOP CDM table", style = pkg.env$styles$heading2) %>%
    my_table_caption("The number of records in all clinical data tables", sourceSymbol = if (optimized) pkg.env$sources$system else pkg.env$sources$cdm) %>%
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
  doc <- doc %>%
    officer::body_add_par("") %>%
    officer::body_add_par("Observation Period", style = pkg.env$styles$heading2)

  if (!is.null(df$observedByMonth$result)) {
    plot <- .recordsCountPlot(as.data.frame(df$observedByMonth$result), hide_legend = TRUE)
    n_active_persons <- df$activePersons$result # dataframe of length one. Missing column name in some cases.
    active_index_date <- dplyr::coalesce(results$cdmSource$SOURCE_RELEASE_DATE, results$cdmSource$CDM_RELEASE_DATE)
    doc <- doc %>%
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
      )
  } else {
    doc <- doc %>%
      my_figure_caption("No observation period by Month results.", sourceSymbol = pkg.env$sources$cdm)
  }
  doc <- doc %>% officer::body_add_par("")

  # Length of first observation period
  if (!is.null(df$observationPeriodLength$result)) {
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
  }

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
      sprintf(
        "Queries executed in %.2f seconds and %.2f seconds",
        df$observationPeriodsPerPerson$duration,
        df$observationPeriodOverlap$duration
      ), 
      style = pkg.env$styles$footnote
    )

  if (!is.null(df$dateRangeByTypeConcept$result)) {
    df$dateRangeByTypeConcept$result <- df$dateRangeByTypeConcept$result %>%
      mutate(
        `Domain` = DOMAIN,
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
  }
  doc <- doc %>%
    officer::body_add_par("Date Range", style = pkg.env$styles$heading2) %>%
    my_table_caption("Minimum and maximum event start date in each table, within an observation period and at least 5 records. Floored to the nearest month.", sourceSymbol = pkg.env$sources$achilles) %>% #nolint
    my_body_add_table_runtime(
      df$dateRangeByTypeConcept,
      alignment = c('l', 'l', rep('r', ncol(df$dateRangeByTypeConcept$result) - 2))
    )

  if (!is.null(df$visitLength$result)) {
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
  }

  doc <- doc %>%
    my_table_caption("Length of stay by visit concept. The length should be interpreted as number of nights, meaning a length of 0 is a same-day visit.", sourceSymbol = pkg.env$sources$achilles) %>%
    my_body_add_table_runtime(df$visitLength)

  # Day of the week and month
  combinedPlot <- cowplot::ggdraw()
  if (!is.null(df$dayOfTheWeek$result) && nrow(df$dayOfTheWeek$result) > 0) {
    dayOfTheWeekPlot <- .heatMapPlot(df$dayOfTheWeek$result, "DAY_OF_THE_WEEK")
    combinedPlot <- combinedPlot +
      cowplot::draw_plot(dayOfTheWeekPlot, x = 0, y = .48, width = .5, height = .5) +
      cowplot::draw_plot_label("Day of the Week", x = .15, y = .99, size = 15)
  } else {
    doc <- doc %>%
      officer::body_add_par("No Day of the Week results.")
  }

  if (!is.null(df$dayOfTheMonth$result) && nrow(df$dayOfTheMonth$result) > 0) {
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

  return(doc)
}