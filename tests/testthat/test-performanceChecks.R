test_that("Performance Checks", {
  performanceResults <- CdmOnboarding::performanceChecks(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    scratchDatabaseSchema = params$scratchDatabaseSchema,
    outputFolder = params$outputFolder
  )

  testthat::expect_type(performanceResults, 'list')
  testthat::expect_named(
    performanceResults,
    c(
      'achillesTiming', 'performanceBenchmark', 'cdmConnectorBenchmark',
      'appliedIndexes', 'sys_details', 'dmsVersion', 'packinfo',
      'hadesPackageVersions', 'darwinPackageVersions'
    ),
    ignore.order = TRUE
  )

  # Check whether all elements have a result, except for appliedIndexes which is not implemented for the test database
  for (name in names(performanceResults)) {
    if (name %in% c("appliedIndexes")) {
      next
    }
    testthat::expect_true(
      !is.null(performanceResults[[name]]),
      info = paste("Element", name, "is null")
    )
  }
})
