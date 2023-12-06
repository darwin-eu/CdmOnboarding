test_that("Performance Checks", {
  performanceResults <- CdmOnboarding::performanceChecks(
    connectionDetails = params$connectionDetails,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    outputFolder = params$outputFolder
  )

  testthat::expect_type(performanceResults, 'list')
  testthat::expect_named(performanceResults, c("achillesTiming", "performanceBenchmark"))
})
