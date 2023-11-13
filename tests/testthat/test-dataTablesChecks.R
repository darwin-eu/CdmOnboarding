test_that("Data Tables Checks", {
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

  testthat::expect_type(results$dataTablesResults, 'list')
})
