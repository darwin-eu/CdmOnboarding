library(stringr)
library(dplyr)

#' Compatibility of CdmOnboarding results
#'
#' @description
#' \code{compat} provides compatibility by converting results from previous versions of CdmOnboarding to the latest version.
#'
#' @param r A list of results from CdmOnboarding.
#' @param fixCasing Recursively uppercase all names?
#' @return A list of results from CdmOnboarding, forwards compatible with v3.
#' @export
compat <- function(r, fixCasing = FALSE) {
  print(sprintf("Converting results from version %s to %s", .get_cdmonboarding_version(r), packageVersion("CdmOnboarding")))

  if (fixCasing) {
    r <- fixCasing(results)
  }

  # General
  r$cdmOnboardingVersion <- dplyr::coalesce(r$cdmOnboardingVersion, .get_cdmonboarding_version(r))
  r$runWithOptimizedQueries <- dplyr::coalesce(r$runWithOptimizedQueries, FALSE)
  r$runWithDbiConnection <- dplyr::coalesce(r$runWithDbiConnection, r$withDbiConnection, FALSE)

  if (.get_cdmonboarding_version(r) >= '2.1') {
    date_format <- "%Y-%m-%d"
  } else {
    date_format <- "%a %b %d %T %Y"
  }
  r$executionDate <- as.Date(r$executionDate, date_format)

  # Data Tables
  r$dataTablesResults$dataTablesCounts <- .fixDataFrameNames(r$dataTablesResults$dataTablesCounts)
  r$dataTablesResults$conceptsPerPerson <- .fixDataFrameNames(r$dataTablesResults$conceptsPerPerson)
  r$dataTablesResults$totalRecords <- .fixDataFrameNames(r$dataTablesResults$totalRecords)
  r$dataTablesResults$observationPeriodLength <- .fixDataFrameNames(r$dataTablesResults$observationPeriodLength)
  r$dataTablesResults$observedByMonth <- .fixDataFrameNames(r$dataTablesResults$observedByMonth)
  r$dataTablesResults$dayOfTheMonth <- .fixDataFrameNames(r$dataTablesResults$dayOfTheMonth)
  r$dataTablesResults$dayOfTheWeek <- .fixDataFrameNames(r$dataTablesResults$dayOfTheWeek)

  # Backwards compatibility, typeConcepts and tableDateRange were merged into dateRangeByTypeConcept (v3)
  if (!is.null(r$dataTablesResults$dateRangeByTypeConcept$result)) {
    if (is.null(r$dataTablesResults$dateRangeByTypeConcept$result$FIRST_START_DATE)) {
      r$dataTablesResults$dateRangeByTypeConcept$result <- r$dataTablesResults$dateRangeByTypeConcept$result %>%
        mutate(
          FIRST_START_DATE = ifelse(!is.na(FIRST_START_MONTH), paste0(FIRST_START_MONTH, '-01'), NA),
          LAST_START_DATE = ifelse(!is.na(LAST_START_MONTH), paste0(LAST_START_MONTH, '-01'), NA),
          FIRST_END_DATE = ifelse(!is.na(FIRST_END_MONTH), paste0(FIRST_END_MONTH, '-01'), NA),
          LAST_END_DATE = ifelse(!is.na(LAST_END_MONTH), paste0(LAST_END_MONTH, '-01'), NA),
          .keep = "unused"
        )
    }

    r$dataTablesResults$tableDateRange$result <- r$dataTablesResults$dateRangeByTypeConcept$result %>%
      summarise(
        FIRST_START_MONTH = min(FIRST_START_DATE),
        LAST_START_MONTH = max(LAST_START_DATE),
        .by = DOMAIN
      )
    r$dataTablesResults$tableDateRange$duration <- NA

    r$dataTablesResults$typeConcepts$result <- r$dataTablesResults$dateRangeByTypeConcept$result %>%
      select(
        DOMAIN,
        TYPE_CONCEPT_ID,
        TYPE_CONCEPT_NAME,
        COUNT = COUNT_VALUE
      )
    r$dataTablesResults$typeConcepts$duration <- NA
  } else {
    r$dataTablesResults$typeConcepts <- .fixDataFrameNames(r$dataTablesResults$typeConcepts)
    r$dataTablesResults$tableDateRange <- .fixDataFrameNames(r$dataTablesResults$tableDateRange)
  }

  # Vocabulary
  r$vocabularyResults$conceptCounts <- .fixDataFrameNames(r$vocabularyResults$conceptCounts)
  r$vocabularyResults$mappingCompleteness <- .fixDataFrameNames(r$vocabularyResults$mappingCompleteness)
  r$vocabularyResults$drugMapping <- .fixDataFrameNames(r$vocabularyResults$drugMapping)

  r$vocabularyResults$unmappedDrugs <- .fixUnmapped(r$vocabularyResults$unmappedDrugs)
  r$vocabularyResults$unmappedConditions <- .fixUnmapped(r$vocabularyResults$unmappedConditions)
  r$vocabularyResults$unmappedMeasurements <- .fixUnmapped(r$vocabularyResults$unmappedMeasurements)
  r$vocabularyResults$unmappedObservations <- .fixUnmapped(r$vocabularyResults$unmappedObservations)
  r$vocabularyResults$unmappedProcedures <- .fixUnmapped(r$vocabularyResults$unmappedProcedures)
  r$vocabularyResults$unmappedDevices <- .fixUnmapped(r$vocabularyResults$unmappedDevices)
  r$vocabularyResults$unmappedVisits <- .fixUnmapped(r$vocabularyResults$unmappedVisits)
  if (!is.null(r$vocabularyResults$unmappedUnits$result)) {
    r$vocabularyResults$unmappedUnits <- .fixUnmapped(r$vocabularyResults$unmappedUnits)
    r$vocabularyResults$unmappedUnitsMeas$result <- r$vocabularyResults$unmappedUnits$result %>%
      filter(DOMAIN == "measurement") %>%  # Renamed from TABLE to DOMAIN with fixDataFrameNames
      select(-DOMAIN)
    r$vocabularyResults$unmappedUnitsMeas$duration <- r$vocabularyResults$unmappedUnits$duration

    r$vocabularyResults$unmappedUnitsObs$result <- r$vocabularyResults$unmappedUnits$result %>%
      filter(DOMAIN == "observation") %>%
      select(-DOMAIN)
    r$vocabularyResults$unmappedUnitsObs$duration <- r$vocabularyResults$unmappedUnits$duration
    r$vocabularyResults$unmappedUnits <- NULL
  } else {
    r$vocabularyResults$unmappedUnitsMeas <- .fixUnmapped(r$vocabularyResults$unmappedUnitsMeas)
    r$vocabularyResults$unmappedUnitsObs <- .fixUnmapped(r$vocabularyResults$unmappedUnitsObs)
  }

  if ("unmappedEpisodes" %in% names(r$vocabularyResults)) {
    r$vocabularyResults$unmappedEpisodes <- .fixUnmapped(r$vocabularyResults$unmappedEpisodes)
  } else {
    r$vocabularyResults$unmappedEpisodes <- NULL
  }

  if ("unmappedSpecialty" %in% names(r$vocabularyResults)) {
    r$vocabularyResults$unmappedSpecialty <- .fixUnmapped(r$vocabularyResults$unmappedSpecialty)
  } else {
    r$vocabularyResults$unmappedSpecialty <- NULL
  }

  if ("unmappedDrugRoute" %in% names(r$vocabularyResults)) {
    r$vocabularyResults$unmappedDrugRoute <- .fixUnmapped(r$vocabularyResults$unmappedDrugRoute)
  } else {
    r$vocabularyResults$unmappedDrugRoute <- NULL
  }

  if ("unmappedValuesObs" %in% names(r$vocabularyResults)) {
    r$vocabularyResults$unmappedValuesObs <- .fixUnmapped(r$vocabularyResults$unmappedValuesObs)
  } else {
    r$vocabularyResults$unmappedValuesObs <- NULL
  }
  
  if ("unmappedValuesMeas" %in% names(r$vocabularyResults)) {
    r$vocabularyResults$unmappedValuesMeas <- .fixUnmapped(r$vocabularyResults$unmappedValuesMeas)
  } else {
    r$vocabularyResults$unmappedValuesMeas <- NULL
  }

  if ("unmappedVisitDetails" %in% names(r$vocabularyResults)) {
    r$vocabularyResults$unmappedVisitDetails <- .fixUnmapped(r$vocabularyResults$unmappedVisitDetails)
  } else {
    r$vocabularyResults$unmappedVisitDetails <- NULL
  }

  r$vocabularyResults$mappedDrugs <- .fixDataFrameNames(r$vocabularyResults$mappedDrugs)
  r$vocabularyResults$mappedConditions <- .fixDataFrameNames(r$vocabularyResults$mappedConditions)
  r$vocabularyResults$mappedMeasurements <- .fixDataFrameNames(r$vocabularyResults$mappedMeasurements)
  r$vocabularyResults$mappedObservations <- .fixDataFrameNames(r$vocabularyResults$mappedObservations)
  r$vocabularyResults$mappedProcedures <- .fixDataFrameNames(r$vocabularyResults$mappedProcedures)
  r$vocabularyResults$mappedDevices <- .fixDataFrameNames(r$vocabularyResults$mappedDevices)
  r$vocabularyResults$mappedVisits <- .fixDataFrameNames(r$vocabularyResults$mappedVisits)
  if (!is.null(r$vocabularyResults$mappedUnits$result)) {
    r$vocabularyResults$mappedUnits <- .fixDataFrameNames(r$vocabularyResults$mappedUnits)

    r$vocabularyResults$mappedUnitsMeas$result <- r$vocabularyResults$mappedUnits$result %>%
      filter(DOMAIN == "measurement") %>%
      select(-DOMAIN)
    r$vocabularyResults$mappedUnitsMeas$duration <- r$vocabularyResults$mappedUnits$duration

    r$vocabularyResults$mappedUnitsObs$result <- r$vocabularyResults$mappedUnits$result %>%
      filter(DOMAIN == "observation") %>%
      select(-DOMAIN)
    r$vocabularyResults$mappedUnitsObs$duration <- r$vocabularyResults$mappedUnits$duration
    r$vocabularyResults$mappedUnits <- NULL
  } else {
    r$vocabularyResults$mappedUnitsMeas <- .fixDataFrameNames(r$vocabularyResults$mappedUnitsMeas)
    r$vocabularyResults$mappedUnitsObs <- .fixDataFrameNames(r$vocabularyResults$mappedUnitsObs)
  }

  if (!("mappedEpisodes" %in% r$vocabularyResults)) {
    r$vocabularyResults$mappedEpisodes <- NULL
  }

  if (!("countConceptRecommended" %in% r$vocabularyResults)) {
    r$vocabularyResults$countConceptRecommended <- NA
  }

  r <- .fixP_RECORDS(r)

  # DED v1.0.6 has three additional columns
  if (!is.null(r$drugExposureDiagnostics$result)) {
    r <- .fixDED(r)
  }

  # Performance
  if (is.null(r$performanceResults$packinfo)) {
    if ('sys_details' %in% names(r)) {
      r$performanceResults$systemDetails <- r$sys_details
    } else if ('sys_details' %in% names(r)) {
      r$performanceResults$systemDetails <- r$performanceResults$sys_details
    }
    if ('dmsVersion' %in% names(r)) {
      r$performanceResults$dmsVersion <- r$dmsVersion
    }
    if ('packinfo' %in% names(r)) {
      r$performanceResults$packinfo <- data.frame(r$packinfo)
    }
    if ('hadesPackageVersions' %in% names(r)) {
      r$performanceResults$hadesPackageVersions <- r$hadesPackageVersions
    }
    if ('darwinPackageVersions' %in% names(r)) {
      r$performanceResults$darwinPackageVersions <- r$darwinPackageVersions
    }
  
    if (is.null(r$performanceResults$darwinPackageVersions)) {
      print("No darwinPackageVersions found, creating empty dataframe")
      r$performanceResults$darwinPackageVersions <- data.frame(
        Package = character(0),
        Version = character(0),
        LibPath = character(0)
      )
    }
  }

  if (is.null(r$performanceResults$hadesPackageVersions$LibPath)) {
    r$performanceResults$hadesPackageVersions$LibPath <- character(nrow(r$performanceResults$hadesPackageVersions))
  }
  if (is.null(r$performanceResults$darwinPackageVersions$LibPath)) {
    r$performanceResults$darwinPackageVersions$LibPath <- character(nrow(r$performanceResults$darwinPackageVersions))
  }
  if (is.null(r$performanceResults$analyticsBenchmark)) {
    r$performanceResults$analyticsBenchmark$result <- data.frame(package_name = character(0), group_level = character(0), estimate_value = numeric(0))
  }
  if (is.null(r$performanceResults$cdmConnectorBenchmark)) {
    r$performanceResults$cdmConnectorBenchmark$result <- data.frame()
  }
  if (is.null(r$performanceResults$cohortBenchmark)) {
    if (!is.null(r$cohortBenchmark)) {
      r$performanceResults$cohortBenchmark <- r$cohortBenchmark
    } else {
      r$performanceResults$cohortBenchmark <- data.frame()
    }
  }  

  return(r)
}

.get_cdmonboarding_version <- function(r) {
  if (is.null(r$cdmOnboardingVersion)) {
    if (is.null(r$packinfo)) {
      t <- r$performanceResults$packinfo
    } else {
      t <- as.data.frame(r$packinfo)
    }
    version_string <- t[t$Package == 'CdmOnboarding', 'Version']
    return(package_version(version_string))
  }
  return(r$cdmOnboardingVersion)
}

.fixDataFrameNames <- function(df) {
  result <- df$result
  if (is.null(result)) {
    return(NULL)
  }

  names(result) <- toupper(names(result))

  names(result) <- names(result) |>
    str_replace("^#$", "ROW_NUM") |>
    str_replace('^C$', "N_CLASSIFICATION_CONCEPTS") |>
    str_replace('^S$', "N_STANDARD_CONCEPTS") |>
    str_replace('^-$', "N_NON_STANDARD_CONCEPTS") |>
    str_replace('^TABLE$', "DOMAIN") |>
    str_replace('PERSON COUNT', "N_PERSONS") |>
    str_replace("CATEGORY", "DOMAIN") |>
    str_replace("AVERAGE", "AVG_VALUE") |>
    str_replace("STD_DEV", "STDEV_VALUE") |>
    str_replace("MEDIAN", "MEDIAN_VALUE") |>
    str_replace("MIN", "MIN_VALUE") |>
    str_replace("MAX", "MAX_VALUE") |>
    str_replace("P10", "P10_VALUE") |>
    str_replace("P25", "P25_VALUE") |>
    str_replace("P75", "P75_VALUE") |>
    str_replace("P90", "P90_VALUE") |>
    str_replace("(?<!SOURCE|COUNT|MEDIAN|AVG|STDEV|MIN|MAX|P\\d\\d)_VALUE", "") |>  # Remove _VALUE suffix if not starting with one of the keywords
    str_replace("%", "P_") |>
    str_replace("#", "N_") |>
    str_replace_all(" ", "_")
  if ('CONCEPT_NAME' %in% names(result)) {
    result$CONCEPT_ID <- dplyr::coalesce(result$CONCEPT_ID, character(nrow(result)))
  }
  if ('N_SUBJECTS' %in% names(result)) {
    result <- select(result, -N_SUBJECTS)
  }

  df$result <- result
  return(df)
}

.fixP_RECORDS <- function(r) {
  for (i in seq_len(nrow(r$dataTablesResults$dataTablesCounts$result))) {
    tablename <- r$dataTablesResults$dataTablesCounts$result[i, "TABLENAME"]
    n_records  <- r$dataTablesResults$dataTablesCounts$result[i, "COUNT"]

    domain <- str_to_title(tablename) |>
      str_replace("_occurrence", "") |>
      str_replace("_exposure", "") |>
      paste0("s")
    elementNames <- paste0(c("mapped", "unmapped"), domain)
    if (tablename == 'measurement') {
      elementNames <- c(elementNames, paste0(c("mapped", "unmapped"), "UnitsMeas"))
    }
    if (tablename == 'observation') {
      elementNames <- c(elementNames, paste0(c("mapped", "unmapped"), "UnitsObs"))
    }
    for (t in elementNames) {
      if (t %in% names(r$vocabularyResults)) {
        r$vocabularyResults[[t]]$result$P_RECORDS <- r$vocabularyResults[[t]]$result$N_RECORDS / n_records * 100
      }
    }
    if (tablename == 'drug_exposure') {
      r$vocabularyResults$drugMapping$result$P_RECORDS <- r$vocabularyResults$drugMapping$result$N_RECORDS / n_records * 100
    }
  }
  return(r)
}

.fixDED <- function(r) {
  if (!('missing_quantity_exp_start_end_days_supply' %in% names(r$drugExposureDiagnostics$result))) {
    r$drugExposureDiagnostics$result$missing_quantity_exp_start_end_days_supply <- NA
    r$drugExposureDiagnostics$result$n_dose_and_missingness <- NA
    r$drugExposureDiagnostics$result$median_daily_dose_q05_q95 <- NA
  }
  r$drugExposureDiagnostics$packageVersion <- 'NA' # TODO: get from results$performanceResults$packinfo$Package
  return(r)
}

.fixUnmapped <- function(df) {
  # add source_concept_id and source_concept_name if missing
  if (!is.null(df$result) && !("SOURCE_CONCEPT_ID" %in% names(df$result))) {
    df$result <- df$result %>%
      mutate(
        SOURCE_CONCEPT_ID = integer(nrow(df$result)),
        SOURCE_CONCEPT_NAME = character(nrow(df$result)),
        .after=SOURCE_VALUE
      )
  }

  #apply general fixes
  df <- .fixDataFrameNames(df)
  return(df)
  }

fixCasing <- function(results) {
  # Recursively iterate through elements in results and convert to uppercase
  convert_data_tables <- function(x) {
    if (is.data.frame(x)) {
      names(x) <- toupper(names(x))
      return(x)
    } else if (is.list(x)) {
      return(lapply(x, convert_data_tables))
    } else {
      return(x)
    }
  }
  results$dataTablesResults <- convert_data_tables(results$dataTablesResults)
  results$vocabularyResults <- convert_data_tables(results$vocabularyResults)
  # results$performanceResults <- convert_data_tables(results$performanceResults)
  results$performanceResults$appliedIndexes$result <- convert_data_tables(results$performanceResults$appliedIndexes$result)
  results$achillesMetadata <- convert_data_tables(results$achillesMetadata)
  results$performanceResults$achillesTiming <- convert_data_tables(results$performanceResults$achillesTiming)

  return(results)
}
