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

  dedResults <- results$drugExposureDiagnostics

  testthat::expect_type(dedResults, 'list')
    testthat::expect_true(
      !is.null(dedResults$result),
      info = paste("The result in drugExposureDiagnostics is null")
    )
})