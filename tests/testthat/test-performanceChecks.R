test_that("Performance Checks", {
  performanceResults <- CdmOnboarding::performanceChecks(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    outputFolder = params$outputFolder
  )

  testthat::expect_type(performanceResults, 'list')
  testthat::expect_named(performanceResults, c(
    'achillesTiming', 'performanceBenchmark', 'cdmConnectorBenchmark',
    'appliedIndexes', 'sys_details', 'dmsVersion', 'packinfo',
    'hadesPackageVersions', 'darwinPackageVersions'
  ))
})
