# Using CDMConnector dataset with Achilles results pre-loaded
# Note: temp database is stored at Sys.getenv("EUNOMIA_DATA_FOLDER")
library(CDMConnector)
library(DatabaseConnector)

datasetName <- "synpuf-1k"
cdmVersion <- "5.3"
server <- CDMConnector::eunomiaDir(datasetName, cdmVersion)

params <- list(
  connectionDetails = createConnectionDetails("duckdb", server = server),
  cdmDatabaseSchema = 'main',
  resultsDatabaseSchema = 'main',
  scratchDatabaseSchema = 'main',  # Required write schema for DED
  databaseId = datasetName,
  cdmVersion = cdmVersion,
  outputFolder = testthat::test_path('test_output'),
  baseUrl = NULL  # connection to WebAPI cannot be tested
)
