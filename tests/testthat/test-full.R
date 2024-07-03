test_that("Full CdmOnboarding executable", {
  skip(message = "tested in parts")
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
    databaseId = params$databaseId,
    outputFolder = params$outputFolder,
    baseUrl = params$baseUrl,
    dqdJsonPath = file.path(params$outputFolder, dqdOutputFile)
  )

  # Result returned, rds written, docx written.
  testthat::expect_type(results, 'list')
  testthat::expect_length(list.files(params$outputFolder, pattern = '*.rds'), 1)
  testthat::expect_length(list.files(params$outputFolder, pattern = '*.docx'), 1)
})
