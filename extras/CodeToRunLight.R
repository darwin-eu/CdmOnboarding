# Install latest version of CdmOnboarding and Achilles if not already installed
if (!require(remotes)) {
  install.packages('remotes')
}
if (!require(CdmOnboarding)) {
  remotes::install_github("DARWIN-EU/CdmOnboarding")
}
if (!require(Achilles)) {
  remotes::install_github("OHDSI/Achilles")  
}

library(CdmOnboarding)

# Fill out the DBI connection details -----------------------------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "", 
  user = "", 
  password = "", 
  server = "", 
  port = "", 
  extraSettings = "",
  pathToDriver = ""
)

# Details for connecting to the CDM
cdmDatabaseSchema <- "yourCdmSchema" # the fully qualified database schema name of the CDM
resultsDatabaseSchema <- "yourResultsSchema" # the fully qualified database schema name of the results schema (that you can write to)
cdmSourceName <- "Your CDM Source" # a human readable name for your CDM source

# Details specific to the database:
authors <- c('<author_1>', '<author_2>') # used on the title page

# (optional) Path to your DQD results file
dqdJsonPath <- 'extras/example_input/dqd_synthea20k.json'

outputFolder <- file.path(getwd(), "output", cdmSourceName)
smallCellCount <- 5

if (FALSE) {
  # If Achilles not yet run, run a minimal set
  Achilles::achilles(
    connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    sourceName = cdmSourceName,
    analysisIds = c(0, 105, 110, 111, 113, 203, 213, 213, 220, 403, 420, 502, 603, 620, 703, 720, 803, 820, 903, 920, 920, 1003, 1020, 1020, 1313, 1313, 1320, 1803, 1820, 1820, 2120),
    outputFolder = outputFolder,
    smallCellCount = smallCellCount
  )
}

results <- CdmOnboarding::cdmOnboarding(
  connectionDetails = connectionDetails,
  cdmSchema = cdmDatabaseSchema,
  resultsSchema = resultsDatabaseSchema,
  databaseId = cdmSourceName,
  authors = authors,
  smallCellCount = smallCellCount,
  outputFolder = outputFolder,
  dqdJsonPath = dqdJsonPath,
  runDedChecks = F,
  runPerformanceChecks = F,
  runWebAPIChecks = F,
  runDataHashByTable = F
)
