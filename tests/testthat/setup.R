#' Setup for Eunomia tests
#' 1. Parameters for connection to Eunomia
#' 2. Run Achilles and store results to drive
#' Note: if Achilles needs to be rerun, delete the eunomia_achilles_data.rds file in the test_output folder

library(Eunomia)
library(Achilles)
library(DatabaseConnector)

params <- list(
    connectionDetails = Eunomia::getEunomiaConnectionDetails(),
    cdmDatabaseSchema = 'main',
    resultsDatabaseSchema = 'main',
    databaseId = 'Eunomia',
    cdmVersion = '5.3',
    outputFolder = testthat::test_path('test_output'),
    baseUrl = "localhost:8080/WebAPI"
)

# Load Achilles results
if (file.exists(file.path(params$outputFolder, 'eunomia_achilles_data.rds'))) {
  print('Loading Achilles results from file')
  achilles_data <- readRDS(file.path(params$outputFolder, 'eunomia_achilles_data.rds'))
  connection <- DatabaseConnector::connect(params$connectionDetails)
  for (tableName in names(achilles_data)) {
    print(sprintf('Inserting %s', tableName))
    DatabaseConnector::insertTable(
      conn = connection,
      tableName = tableName,
      data = achilles_data[[tableName]],
      createTable = TRUE
    )
  }
  DatabaseConnector::disconnect(connection)
} else {
  # Run Achilles and store results
  Achilles::achilles(
    connectionDetails = params$connectionDetails,
    cdmDatabaseSchema = params$cdmDatabaseSchema,
    resultsDatabaseSchema = params$resultsDatabaseSchema,
    outputFolder = file.path(params$outputFolder, 'achilles-logs'),
    analysisIds = c(0, 105, 110, 111, 113, 117, 220, 420, 502, 620, 720, 820, 920, 1020, 1820, 2102, 2120, 203, 403, 603, 703, 803, 903, 920, 1003, 1020, 1320, 1411, 1803, 1820)
  )
  connection <- DatabaseConnector::connect(params$connectionDetails)

  # Export data from a table in your database to a data frame
  achilles_data <- list(
    achilles_analysis = DatabaseConnector::querySql(
      connection,
      "SELECT * FROM achilles_analysis"
    ),
    achilles_results = DatabaseConnector::querySql(
      connection,
      "SELECT * FROM achilles_results"
    ),
    achilles_results_dist = DatabaseConnector::querySql(
      connection,
      "SELECT * FROM achilles_results_dist",
    )
  )
  DatabaseConnector::disconnect(connection)
  saveRDS(achilles_data, file.path(params$outputFolder, 'eunomia_achilles_data.rds'))
  #TODO: clean up of achilles data rds for run on Github Actions
}