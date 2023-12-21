test_that("Vocabulary Tables Checks with Optimize", {
  vocabularyResults <- CdmOnboarding::vocabularyChecks(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    outputFolder = params$outputFolder,
    optimize = TRUE
  )

  testthat::expect_type(vocabularyResults, 'list')
  testthat::expect_named(vocabularyResults, c(
    "version", "mappingTempTableCreation", "mappingCompleteness", 
    "drugMapping", "unmappedDrugs", "unmappedConditions", "unmappedMeasurements", 
    "unmappedObservations", "unmappedProcedures", "unmappedDevices", 
    "unmappedVisits", "unmappedVisitDetails", "unmappedUnitsMeas", "unmappedUnitsObs", "unmappedValuesMeas", "unmappedValuesObs", "unmappedDrugRoute",
    "mappedDrugs", "mappedConditions", "mappedMeasurements", "mappedObservations", 
    "mappedProcedures", "mappedDevices", "mappedVisits", "mappedVisitDetails", "mappedUnitsMeas",
    "mappedUnitsObs", "mappedValuesMeas", "mappedValuesObs", "mappedDrugRoute", "conceptCounts", "vocabularyCounts", 
    "sourceConceptFrequency", "sourceConceptMap"
    )
  )

  # Check each element has a non-null result, except version and mappingTempTableCreation
  for (name in names(vocabularyResults)) {
    if (name %in% c("version", "mappingTempTableCreation")) {
      next
    }
    testthat::expect_true(
      !is.null(vocabularyResults[[name]]$result),
      info = paste("The result in", name, "is null")
    )
  }
})
