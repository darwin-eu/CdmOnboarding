#' Compatibility of CdmOnboarding results
#'
#' @description
#' \code{compat} provides compatibility by converting results from previous versions of CdmOnboarding to the latest version.
#'
#' @param r A list of results from CdmOnboarding.
#' @param target_version The version to convert the results to, only v3 supported.
#' @return A list of results from CdmOnboarding, forwards compatible with v3.
#' @export
#' @importFrom stringr str_replace str_replace_all str_to_title
compat <- function(r, target_version = package_version('3.0.0')) {
    if (target_version$major != 3) {
        print("Only target version v3 is supported")
    }
    print(sprintf("Converting results from version %s to %s", .get_cdmonboarding_version(r), target_version))

    # General
    r$cdmOnboardingVersion <- dplyr::coalesce(r$cdmOnboardingVersion, .get_cdmonboarding_version(r))
    r$runWithOptimizedQueries <- dplyr::coalesce(r$runWithOptimizedQueries, FALSE)

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
    if (!is.null(r$dataTablesResults$dateRangeByTypeConcept)) {
        if(is.null(r$dataTablesResults$dateRangeByTypeConcept$result$FIRST_START_DATE)) {
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

    r$vocabularyResults$unmappedDrugs <- .fixDataFrameNames(r$vocabularyResults$unmappedDrugs)
    r$vocabularyResults$unmappedConditions <- .fixDataFrameNames(r$vocabularyResults$unmappedConditions)
    r$vocabularyResults$unmappedMeasurements <- .fixDataFrameNames(r$vocabularyResults$unmappedMeasurements)
    r$vocabularyResults$unmappedObservations <- .fixDataFrameNames(r$vocabularyResults$unmappedObservations)
    r$vocabularyResults$unmappedProcedures <- .fixDataFrameNames(r$vocabularyResults$unmappedProcedures)
    r$vocabularyResults$unmappedDevices <- .fixDataFrameNames(r$vocabularyResults$unmappedDevices)
    r$vocabularyResults$unmappedVisits <- .fixDataFrameNames(r$vocabularyResults$unmappedVisits)
    if (!is.null(r$vocabularyResults$unmappedUnits)) {
        r$vocabularyResults$unmappedUnits <- .fixDataFrameNames(r$vocabularyResults$unmappedUnits)
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
        r$vocabularyResults$unmappedUnitsMeas <- .fixDataFrameNames(r$vocabularyResults$unmappedUnitsMeas)
        r$vocabularyResults$unmappedUnitsObs <- .fixDataFrameNames(r$vocabularyResults$unmappedUnitsObs)
    }

    r$vocabularyResults$mappedDrugs <- .fixDataFrameNames(r$vocabularyResults$mappedDrugs)
    r$vocabularyResults$mappedConditions <- .fixDataFrameNames(r$vocabularyResults$mappedConditions)
    r$vocabularyResults$mappedMeasurements <- .fixDataFrameNames(r$vocabularyResults$mappedMeasurements)
    r$vocabularyResults$mappedObservations <- .fixDataFrameNames(r$vocabularyResults$mappedObservations)
    r$vocabularyResults$mappedProcedures <- .fixDataFrameNames(r$vocabularyResults$mappedProcedures)
    r$vocabularyResults$mappedDevices <- .fixDataFrameNames(r$vocabularyResults$mappedDevices)
    r$vocabularyResults$mappedVisits <- .fixDataFrameNames(r$vocabularyResults$mappedVisits)
    if (!is.null(r$vocabularyResults$mappedUnits)) {
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
    r <- .fixP_RECORDS(r)
    
    if (is.null(r$performanceResults$packinfo)) {
        r$performanceResults$sys_details <- r$sys_details
        r$performanceResults$dmsVersion <- r$dmsVersion
        r$performanceResults$packinfo <- data.frame(r$packinfo)
        r$performanceResults$hadesPackageVersions <- r$hadesPackageVersions
        r$performanceResults$darwinPackageVersions <- r$darwinPackageVersions
    
        r$packinfo <- NULL
        r$dmsVersion <- NULL
        r$sys_details <- NULL
        r$hadesPackageVersions <- NULL
    }

    return(r)
}


.get_cdmonboarding_version <- function(r) {
    if (is.null(r$cdmOnboardingVersion)) {
        t <- as.data.frame(r$packinfo)
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
        str_replace("MIN", "MIN_VALUE") |>
        str_replace("MAX", "MAX_VALUE") |>
        str_replace("P10", "P10_VALUE") |>
        str_replace("P25", "P25_VALUE") |>
        str_replace("P75", "P75_VALUE") |>
        str_replace("P90", "P90_VALUE") |>
        str_replace("(?<!SOURCE|COUNT|AVG|STDEV|MIN|MAX|P\\d\\d)_VALUE", "") |>
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
