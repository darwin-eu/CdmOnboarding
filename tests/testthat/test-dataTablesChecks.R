test_that("Data Tables Checks", {
  dataTablesResults <- CdmOnboarding::dataTablesChecks(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    cdmVersion = params$cdmVersion,
    outputFolder = params$outputFolder
  )

  testthat::expect_type(dataTablesResults, 'list')

  testthat::expect_named(dataTablesResults, c(
      "dataTablesCounts", "totalRecords", "recordsPerPerson", "conceptsPerPerson",
      "observationPeriodLength", "activePersons", "observedByMonth",
      "typeConcepts", "tableDateRange", "dayOfTheWeek", "dayOfTheMonth",
      "observationPeriodsPerPerson", "observationPeriodOverlap",
      "dayMonthYearOfBirth"
    )
  )

  for (name in names(dataTablesResults)) {
    testthat::expect_true(
      !is.null(dataTablesResults[[name]]$result),
      info = paste("The result in", name, "is null")
    )
  }
})
