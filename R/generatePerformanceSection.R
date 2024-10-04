# @file generatePerformanceSection.R
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

#' Generates the Performance section in the Results Document
#'
#' @param doc officer document object to add the section to
#' @param results Results object from \code{cdmOnboarding}
generatePerformanceSection <- function(doc, results) {
  df <- results$performanceResults
  # Installed packages
  allPackages <- data.frame(
    Package = c(getHADESpackages(), getDARWINpackages()),
    Version = "",
    Organisation = c(rep("OHDSI HADES", length(getHADESpackages())), rep("DARWIN EU\u00AE", length(getDARWINpackages())))
  )

  packageVersions <- dplyr::union(df$hadesPackageVersions, df$darwinPackageVersions) %>%
    dplyr::full_join(allPackages, by = c("Package")) %>%
    dplyr::mutate(
      Version = dplyr::coalesce(.data$Version.x, "Not installed")
    ) %>%
    # Sorting on LibPath to get packages in same environment together (if multiple versions of the same package installed due to renvs)
    dplyr::arrange(.data$Organisation, .data$LibPath, .data$Package) %>%
    dplyr::select(.data$Organisation, .data$Package, .data$Version)

  doc <- doc %>%
    officer::body_add_par("R packages", style = pkg.env$styles$heading2) %>%
    my_table_caption(
      "Installed versions of R packages from DARWIN EU\u00AE and the OHDSI Health Analytics Data-to-Evidence Suite (HADES).",
      sourceSymbol = pkg.env$sources$system
    ) %>%
    my_body_add_table(packageVersions)

  #system detail
  doc <- doc %>%
    officer::body_add_par("System Information", style = pkg.env$styles$heading2) %>%
    officer::body_add_par(paste0("Installed R version: ", df$sys_details$r_version$version.string)) %>%
    officer::body_add_par(paste0("System CPU vendor: ", df$sys_details$cpu$vendor_id, collapse = ", ")) %>%
    officer::body_add_par(paste0("System CPU model: ", df$sys_details$cpu$model_name, collapse = ", ")) %>%
    officer::body_add_par(paste0("System CPU number of cores: ", df$sys_details$cpu$no_of_cores, collapse = ", ")) %>%
    officer::body_add_par(paste0("System RAM: ", prettyunits::pretty_bytes(as.numeric(df$sys_details$ram, collapse = ", ")))) %>%
    officer::body_add_par(paste0("DBMS: ", df$dmsVersion)) %>%
    officer::body_add_par(paste0("WebAPI version: ", results$webAPIversion)) %>%
    officer::body_add_par("")

  doc <- doc %>%
    officer::body_add_par("Query Performance", style = pkg.env$styles$heading2)
  if (!is.null(df$performanceBenchmark$result)) {
    n_relations <- df$performanceBenchmark$result
    benchmark_query_time <- df$performanceBenchmark$duration
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

  if (!is.null(df$cdmConnectorBenchmark$result)) {
    df$cdmConnectorBenchmark$result <- df$cdmConnectorBenchmark$result %>%
      select(
        `Task` = .data$task,
        `Time taken (s)` = .data$time_taken_secs,
        `Time taken (min)` = .data$time_taken_mins
      )
    doc <- doc %>%
      my_table_caption("CDMConnector benchmark of the OMOP CDM tables.", sourceSymbol = pkg.env$sources$cdm) %>%
      my_body_add_table_runtime(df$cdmConnectorBenchmark)
  } else {
    doc <- doc %>%
      officer::body_add_par("CDMConnector benchmark of the OMOP CDM tables could not be retrieved", style = pkg.env$styles$highlight)
  }

  doc <- doc %>%
    officer::body_add_par("Applied indexes", style = pkg.env$styles$heading2)
  if (!is.null(df$appliedIndexes$result)) {
    expectedIndexes <- .getExpectedIndexes(results$cdmSource$CDM_VERSION)

    # filter to the OMOP CDM tables only
    if (!is.null(results$dataTablesResults$dataTablesCounts)) {
      omop_table_names <- results$dataTablesResults$dataTablesCounts$result[, 1]
      df$appliedIndexes$result <- df$appliedIndexes$result %>%
        dplyr::filter(.data$TABLENAME %in% omop_table_names)
    }

    df$appliedIndexes$result$actual <- 1
    expectedIndexes$expected <- 1
    indexOverview <- df$appliedIndexes$result %>%
      dplyr::mutate(type = substr(.data$INDEXNAME, 1, 3)) %>%
      dplyr::full_join(expectedIndexes, by = join_by(TABLENAME, INDEXNAME, type)) %>%
      dplyr::group_by(.data$TABLENAME, .data$type) %>%
      dplyr::summarize(
        n_indexes_applied = sum(.data$actual, na.rm = TRUE),
        n_indexes_expected = sum(.data$expected, na.rm = TRUE),
        n_indexes_missing = sum(is.na(.data$actual), na.rm = TRUE)
      ) %>%
      tidyr::pivot_wider(
        names_from = .data$type,
        values_from = c(.data$n_indexes_applied, .data$n_indexes_expected, .data$n_indexes_missing),
        names_glue = "{.name}",  #_{.value}
        values_fill = 0,
        names_sort = TRUE
      ) %>%
      dplyr::select(
        .data$TABLENAME,
        `xpk - Applied` = .data$n_indexes_applied_xpk,
        `xpk - Expected` = .data$n_indexes_expected_xpk,
        `xpk - Missing` = .data$n_indexes_missing_xpk,
        `idx - Applied` = .data$n_indexes_applied_idx,
        `idx - Expected` = .data$n_indexes_expected_idx,
        `idx - Missing` = .data$n_indexes_missing_idx
      )
    indexTotals <- data.frame(TABLENAME  = "Total", t(colSums(indexOverview[, -1])))
    names(indexTotals) <- names(indexOverview)
    indexOverview <- rbind(indexOverview, indexTotals)

    doc <- doc %>%
      my_table_caption("The number of indexes applied on the OMOP CDM tables. xpk=primary key, idx=index.", sourceSymbol = pkg.env$sources$system) %>%
      my_body_add_table(indexOverview) %>%
      my_body_add_runtime(df$appliedIndexes$duration)
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

  arTimings <- df$achillesTiming$result
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
      longestAnalysis <- arTimings %>% slice_max(.data$DURATION, n = 1, na_rm = TRUE)
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
    doc <- doc %>% my_body_add_table_runtime(df$achillesTiming)
  } else {
    doc <- doc %>%
      officer::body_add_par("Query did not return results", style = pkg.env$styles$highlight)
  }
  return(doc)
}
