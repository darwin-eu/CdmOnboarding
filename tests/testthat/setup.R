library(Eunomia)
connectionDetails <- Eunomia::getEunomiaConnectionDetails()

hasAchillesResults <- CdmOnboarding:::.checkAchillesTablesExist(connectionDetails, "main", testthat::test_path())

if (!hasAchillesResults) {
  Achilles::achilles(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = "main",
    resultsDatabaseSchema = "main",
    analysisIds = c(0, 105, 110, 111, 117, 220, 420, 502, 620, 720, 820, 920, 1020, 1820, 2102, 2120, 203, 403, 603, 703, 803, 903, 920, 1003, 1020, 1320, 1411, 1803, 1820)
  )
}
