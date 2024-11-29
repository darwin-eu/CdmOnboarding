test_that("WebAPI Checks", {
  skip(message = "requires network connection")
  results <- CdmOnboarding::cdmOnboarding(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    outputFolder = params$outputFolder,
    databaseId = params$databaseId,
    dqdJsonPath = NULL,
    baseUrl = params$baseUrl,
    runDataTablesChecks = FALSE,
    runVocabularyChecks = FALSE,
    runPerformanceChecks = FALSE,
    runWebAPIChecks = TRUE,
    runDedChecks = FALSE,
    runCohortBenchmarkChecks = FALSE
  )

  testthat::expect_type(results$webAPIversion, 'character')
})