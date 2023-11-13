test_that("Performance Checks", {
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      dqdJsonPath = NULL,
      runDataTablesChecks = FALSE,
      runVocabularyChecks = FALSE,
      runPerformanceChecks = TRUE,
      runWebAPIChecks = FALSE,
      runDedChecks = FALSE
    )
  )
  
  testthat::expect_type(results$performanceResults, 'list')
})