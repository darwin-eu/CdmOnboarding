#' @file testCompat.R Test functionality of compat

library(stringr)
library(tidyverse)
source('R/compat.R')
options(error = message)

#' Recursively get the names of all fields
get_names <- function(myList, current_field_name = "", depth = 0) {
  # Get the names
  field_names <- names(myList)

  # If no names, return this branch
  if (is.null(field_names)) {
    return(current_field_name)
  }

  # If names, loop through them
  result <- c(current_field_name)
  for (field_name in field_names) {
    element <- myList[[field_name]]
    next_field_name <- paste0(current_field_name, "$", field_name)
    result <- c(result, get_names(element, next_field_name, depth = depth + 1))
  }
  return(result)
}

results_v1 <- readRDS('./extras/version_compatibility/onboarding_results_synthea20k-v1.0.1.rds')
print(CdmOnboarding:::.get_cdmonboarding_version(results_v1))

results_v20 <- readRDS('./extras/version_compatibility/onboarding_results_synthea20k-v2.0.0.rds')
print(CdmOnboarding:::.get_cdmonboarding_version(results_v20))

results_v21 <- readRDS('./extras/version_compatibility/onboarding_results_synthea20k-v2.1.0.rds')
print(CdmOnboarding:::.get_cdmonboarding_version(results_v21))

results_v22 <- readRDS('./extras/version_compatibility/onboarding_results_synthea20k-v2.2.0.rds')
print(CdmOnboarding:::.get_cdmonboarding_version(results_v22))

results_v30 <- readRDS('./extras/version_compatibility/onboarding_results_synthea20k-v3.0.0.rds')
print(CdmOnboarding:::.get_cdmonboarding_version(results_v30))

results_v31 <- readRDS('./extras/version_compatibility/onboarding_results_synthea20k-v3.1.0.rds')
print(CdmOnboarding:::.get_cdmonboarding_version(results_v31))

results_v10_fixed <- compat(results_v1)
results_v20_fixed <- compat(results_v20)
results_v21_fixed <- compat(results_v21)
results_v22_fixed <- compat(results_v22)
results_v30_fixed <- compat(results_v30)
results_v31_fixed <- compat(results_v31)

my_setdiff <- function(a, b) {
  set <- setdiff(a, b)
  set_cleaned <- c()
  for (x in sort(set)) {
    parent_already_in_s <- FALSE
    for (y in set_cleaned) {
      if (startsWith(x, paste0(y, '$'))) {
        parent_already_in_s <- TRUE
      }
    }
    if (!parent_already_in_s) {
      set_cleaned <- c(set_cleaned, x)
    }
  }
  return(set_cleaned)
}

my_compare <- function(x, y) {
  names_x <- get_names(x)
  names_y <- get_names(y)

  a <- my_setdiff(names_x, names_y)
  b <- my_setdiff(names_y, names_x)
  print('In x but not in y:')
  print(a)
  print('In y but not in x:')
  print(b)
  print(sprintf('In x but not in y: %d elements.\nIn y but not in x: %d elements', length(a), length(b)))
}

my_compare(results_v10_fixed, results_v20_fixed) # "In x but not in y: 14 elements.\nIn y but not in x: 9 elements"
# Removed: 13 packInfo elements (Built, Depends, Enhances, etc.)
# Added: achillesMetadata, conceptsPerPerson$N_PERSONS, activePersons, observationPeriodLength, observedByMonth, tableDateRange, typeConcepts, dqdResults, mappingTempTableCreation

my_compare(results_v20_fixed, results_v21_fixed) # "In x but not in y: 0 elements.\nIn y but not in x: 3 elements"
# Removed: none
# Added: dedResults, mappedDrugRoute, unmappedDrugRoute

my_compare(results_v21_fixed, results_v22_fixed) # "In x but not in y: 0 elements.\nIn y but not in x: 1 elements"
# Removed: none
# Added: performanceResults$dmsVersion

my_compare(results_v22_fixed, results_v30_fixed) # "In x but not in y: 1 elements.\nIn y but not in x: 25 elements" -> includes dqdResults and dedResults
# Removed: missingPackages
# Added: dateRangeByTypeConcept, dayMonthYearOfBirth, dayOfTheMonth, dayOfTheWeek, observationPeriodOverlap, observationPeriodsPerPerson, visitLength
#        appliedIndexes, darwinPackageVersions, packinfo$LibPath, packinfo$URL,
#        mappedValuesMeas, mappedValuesObs, mappedVisitDetails, unmappedValuesMeas, unmappedValuesObs, unmappedVisitDetails

my_compare(results_v30_fixed, results_v31_fixed) # "In x but not in y: 0 elements.\nIn y but not in x: 3 elements"
# Removed: none
# Added: sys_details$machine$sizeof.time_t, mappedSpecialty, unmappedSpecialty -> should be part of v3.0 as well

my_compare(results_v22, results_v22_fixed) # "In x but not in y: 4 elements.\nIn y but not in x: 4 elements"
my_compare(results_v30, results_v30_fixed) # "In x but not in y: 17 elements.\nIn y but not in x: 11 elements"
my_compare(results_v31, results_v31_fixed) # "In x but not in y: 17 elements.\nIn y but not in x: 11 elements"

#' TODO:
#' - Run v21 and v22 with dqdJson and drugExposureDiagnostics
#' - Compare each subsequent version (after fix), document added elements. No elements should be removed
#' - Compare each against latest version (v3), document differences.
