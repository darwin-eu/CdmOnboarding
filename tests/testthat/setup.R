library(Eunomia)
params <- list(
    connectionDetails = Eunomia::getEunomiaConnectionDetails(),
    cdmDatabaseSchema = 'main',
    resultsDatabaseSchema = 'main',
    databaseId = 'Eunomia',
    outputFolder = testthat::test_path('test_output'),
    baseUrl = "localhost:8080/WebAPI/"
)

hasAchillesResults <- CdmOnboarding:::.checkAchillesTablesExist(
  connectionDetails = params$connectionDetails,
  resultsDatabaseSchema = params$resultsDatabaseSchema
)

if (!hasAchillesResults) {
  Achilles::achilles(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    outputFolder = file.path(params$outputFolder, 'achilles-logs'),
    analysisIds = c(0, 105, 110, 111, 117, 220, 420, 502, 620, 720, 820, 920, 1020, 1820, 2102, 2120, 203, 403, 603, 703, 803, 903, 920, 1003, 1020, 1320, 1411, 1803, 1820)
  )
}
