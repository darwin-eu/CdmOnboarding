test_that("Vocabulary Tables Checks", {
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      dqdJsonPath = NULL,
      runDataTablesChecks = FALSE,
      runVocabularyChecks = TRUE,
      runPerformanceChecks = FALSE,
      runWebAPIChecks = FALSE,
      runDedChecks = FALSE
    )
  )
  
  testthat::expect_type(results$vocabularyResults, 'list')
})
