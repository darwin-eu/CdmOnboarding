test_that("Drug Exposure Diagnostics Checks", {
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      runDataTablesChecks = FALSE,
      runVocabularyChecks = FALSE,
      runPerformanceChecks = FALSE,
      runWebAPIChecks = FALSE,
      runDedChecks = TRUE
    )
  )
  
  testthat::expect_type(results$drugExposureDiagnostics, 'list')
})