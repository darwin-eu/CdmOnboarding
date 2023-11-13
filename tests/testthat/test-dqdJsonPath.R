test_that("DQD Json", {
  # Run a minimal DQD
  library(DataQualityDashboard)
  dqdOutputFile <- 'dqd_test.json'
  dqd_result <- DataQualityDashboard::executeDqChecks(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    cdmSourceName = params$databaseId,
    outputFolder = params$outputFolder,
    outputFile = dqdOutputFile,
    checkLevels = "TABLE"
  )

  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      dqdJsonPath = file.path(params$outputFolder, dqdOutputFile),
      runDataTablesChecks = FALSE,
      runVocabularyChecks = FALSE,
      runPerformanceChecks = FALSE,
      runWebAPIChecks = FALSE,
      runDedChecks = FALSE
    )
  )

  testthat::expect_type(results$dqdResults, 'list')
})
