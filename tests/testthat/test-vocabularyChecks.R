test_that("Vocabulary Tables Checks", {
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    c(
      params,
      dqdJsonPath = NULL,
      runDataTablesChecks = FALSE,
      runVocabularyChecks = TRUE,
      runPerformanceChecks = FALSE,
      runWebAPIChecks = FALSE,
      runDedChecks = FALSE
    )
  )

  testthat::expect_type(results$vocabularyResults, 'list')
  testthat::expect_named(results$vocabularyResults, c(
    "version", "mappingTempTableCreation", "mappingCompleteness", 
    "drugMapping", "unmappedDrugs", "unmappedConditions", "unmappedMeasurements", 
    "unmappedObservations", "unmappedProcedures", "unmappedDevices", 
    "unmappedVisits", "unmappedUnitsMeas", "unmappedUnitsObs", "unmappedDrugRoute", 
    "mappedDrugs", "mappedConditions", "mappedMeasurements", "mappedObservations", 
    "mappedProcedures", "mappedDevices", "mappedVisits", "mappedUnitsMeas", 
    "mappedUnitsObs", "mappedDrugRoute", "conceptCounts", "vocabularyCounts", 
    "sourceConceptFrequency", "sourceConceptMap"
    )
  )
})
