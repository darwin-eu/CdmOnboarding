test_that("Full CdmOnboarding executable", {
  results <- CdmOnboarding::cdmOnboarding(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    databaseId = params$databaseId,
    outputFolder = params$outputFolder,
    baseUrl = params$baseUrl,
    dqdJsonPath = params$dqdJsonPath
  )

  # Result returned, rds written, docx written.
  testthat::expect_type(results, 'list')
  testthat::expect_length(list.files(params$outputFolder, pattern = '*.rds'), 1)
  testthat::expect_length(list.files(params$outputFolder, pattern = '*.docx'), 1)
})
