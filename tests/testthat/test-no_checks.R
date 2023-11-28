test_that("No Checks", {
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      runDataTablesChecks = FALSE,
      runVocabularyChecks = FALSE,
      runPerformanceChecks = FALSE,
      runWebAPIChecks = FALSE,
      runDedChecks = FALSE
    )
  )

  testthat::expect_type(results, 'list')
})
