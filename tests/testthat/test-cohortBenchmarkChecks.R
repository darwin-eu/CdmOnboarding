test_that("Benchmark Checks", {
  cohortBenchmarkResults <- CdmOnboarding:::.runCohortBenchmark(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    scratchDatabaseSchema = params$scratchDatabaseSchema
  )

  testthat::expect_type(cohortBenchmarkResults, 'list')
})