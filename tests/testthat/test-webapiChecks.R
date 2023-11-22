test_that("Vocabulary Tables Checks", {
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      dqdJsonPath = NULL,
      runDataTablesChecks = FALSE,
      runVocabularyChecks = FALSE,
      runPerformanceChecks = FALSE,
      runWebAPIChecks = TRUE,
      runDedChecks = FALSE
    )
  )

  testthat::expect_type(results$webAPIversion, 'character')
})