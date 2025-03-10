test_that("DQD Json", {
  results <- CdmOnboarding::cdmOnboarding(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    outputFolder = params$outputFolder,
    databaseId = params$databaseId,
    dqdJsonPath = params$dqdJsonPath,
    baseUrl = params$baseUrl,
    runDataTablesChecks = FALSE,
    runVocabularyChecks = FALSE,
    runPerformanceChecks = FALSE,
    runWebAPIChecks = FALSE,
    runDedChecks = FALSE,
    runCohortBenchmarkChecks = FALSE
  )

  testthat::expect_type(results$dqdResults, 'list')
  testthat::expect_named(results$dqdResults, c("version", "overview", "startTimestamp", "executionTime"), ignore.order = TRUE)
})
