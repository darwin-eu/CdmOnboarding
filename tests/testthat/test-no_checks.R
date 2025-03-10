test_that("No Checks", {
  results <- CdmOnboarding::cdmOnboarding(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    outputFolder = params$outputFolder,
    databaseId = params$databaseId,
    dqdJsonPath = NULL,
    baseUrl = NULL,
    runDataTablesChecks = FALSE,
    runVocabularyChecks = FALSE,
    runPerformanceChecks = FALSE,
    runWebAPIChecks = FALSE,
    runDedChecks = FALSE,
    runCohortBenchmarkChecks = FALSE
  )

  testthat::expect_type(results, 'list')
})
