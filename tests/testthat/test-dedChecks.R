test_that("Drug Exposure Diagnostics Checks", {
  dedResults <- CdmOnboarding:::.runDedChecks(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    scratchDatabaseSchema = params$scratchDatabaseSchema
  )

  testthat::expect_type(dedResults, 'list')
  testthat::expect_true(
    !is.null(dedResults$result),
    info = paste("The result in drugExposureDiagnostics is null")
  )
})
