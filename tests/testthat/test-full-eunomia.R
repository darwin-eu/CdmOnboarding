test_that("Full CdmOnboarding executable", {
  results <- CdmOnboarding::cdmOnboarding(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = 'main',
    resultsDatabaseSchema = 'main',
    databaseId = 'Eunomia',
    baseUrl = baseUrl,
    outputFolder = testthat::test_path(),
    dqdJsonPath = NULL
  )

  testthat::expect_type(results, 'list')
})
