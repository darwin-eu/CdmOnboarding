test_that("Drug Exposure Diagnostics Checks", {
  # TODO: fails on Eunomia because DatabaseConnectorDbiConnection connection not supported
  # Will be fixed by #103
  dedResults <- CdmOnboarding:::.runDedChecks(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema
  )

  testthat::expect_type(dedResults, 'list')
  testthat::expect_true(
      !is.null(dedResults$result),
      info = paste("The result in drugExposureDiagnostics is null")
  )
})