test_that("Full CdmOnboarding executable", {
  skip(message = "covered by individual tests")
  results <- CdmOnboarding::cdmOnboarding(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    databaseId = params$databaseId,
    outputFolder = params$outputFolder,
    baseUrl = params$baseUrl,
    dqdJsonPath = params$dqdJsonPath
  )

  # Result returned
  testthat::expect_type(results, 'list')
})
