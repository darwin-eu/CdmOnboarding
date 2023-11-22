test_that("Data Tables Checks", {
  # TODO: use CdmOnboarding::dataTablesChecks() instead of CdmOnboarding::cdmOnboarding()
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      runDataTablesChecks = TRUE,
      runVocabularyChecks = FALSE,
      runPerformanceChecks = FALSE,
      runWebAPIChecks = FALSE,
      runDedChecks = FALSE
    )
  )

  dataTablesResults <- results$dataTablesResults
  testthat::expect_type(dataTablesResults, 'list')

  testthat::expect_named(
    dataTablesResults,
    c("dataTablesCounts", "totalRecords", "recordsPerPerson", "conceptsPerPerson", "observationPeriodLength", "activePersons", "observedByMonth", "typeConcepts", "tableDateRange")
  )

  for (name in names(dataTablesResults)) {
    testthat::expect_true(
      !is.null(dataTablesResults[[name]]$result),
      info = paste("The result in", name, "is null")
    )
  }
})
