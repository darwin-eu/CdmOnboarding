test_that("DQD Json", {
  # TODO: run DQD, write file to params$outputFolder
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      dqdJsonPath = '',
      runDataTablesChecks = FALSE,
      runVocabularyChecks = FALSE,
      runPerformanceChecks = FALSE,
      runWebAPIChecks = FALSE,
      runDedChecks = FALSE
    )
  )

  testthat::expect_type(results$dqdResults, 'list')
})
