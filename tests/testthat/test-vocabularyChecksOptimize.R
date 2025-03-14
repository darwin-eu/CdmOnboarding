test_that("Vocabulary Tables Checks with Optimize", {
  skip(message = "not used")
  vocabularyResults <- CdmOnboarding::vocabularyChecks(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    cdmVersion = params$cdmVersion,
    outputFolder = params$outputFolder,
    optimize = TRUE
  )

  testthat::expect_type(vocabularyResults, 'list')
  testthat::expect_named(
    vocabularyResults,
    c(
      "version", "mappingTempTableCreation", "mappingCompleteness",
      "drugMapping", "unmappedDrugs", "unmappedConditions", "unmappedMeasurements",
      "unmappedObservations", "unmappedProcedures", "unmappedDevices", 'unmappedEpisodes',
      "unmappedVisits", "unmappedVisitDetails", "unmappedUnitsMeas", 'mappedEpisodes',
      "unmappedUnitsObs", "unmappedValuesMeas", "unmappedValuesObs",
      "unmappedDrugRoute", "unmappedSpecialty", "mappedDrugs", "mappedConditions",
      "mappedMeasurements", "mappedObservations", "mappedProcedures",
      "mappedDevices", "mappedVisits", "mappedVisitDetails", "mappedUnitsMeas",
      "mappedUnitsObs", "mappedValuesMeas", "mappedValuesObs", "mappedDrugRoute",
      "mappedSpecialty", "conceptCounts", "vocabularyCounts", "sourceConceptFrequency",
      "sourceConceptMap"
    ),
    ignore.order = TRUE
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
