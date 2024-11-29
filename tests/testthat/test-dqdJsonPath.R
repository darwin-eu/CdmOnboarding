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

  results <- CdmOnboarding::cdmOnboarding(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    outputFolder = params$outputFolder,
    databaseId = params$databaseId,
    dqdJsonPath = file.path(params$outputFolder, dqdOutputFile),
    baseUrl = params$baseUrl,
    runDataTablesChecks = FALSE,
    runVocabularyChecks = FALSE,
    runPerformanceChecks = FALSE,
    runWebAPIChecks = FALSE,
    runDedChecks = FALSE
  )

  testthat::expect_type(results$dqdResults, 'list')
  testthat::expect_named(results$dqdResults, c("version", "overview", "startTimestamp", "executionTime"), ignore.order = TRUE)
})
