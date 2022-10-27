# *******************************************************
# -----------------INSTRUCTIONS -------------------------
# *******************************************************
#
#-----------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------
# This CodeToRun.R is provided as an example of how to run this package.
# Below you will find 2 sections: the 1st is for installing the dependencies
# required to run the package and the 2nd for running the package.

library(CdmOnboarding)

# Details for connecting to the server
dbms <- ''
user <- ''
password <- ''
server <- ''
port <- 
pathToDriver <- ''  # Driver can be installed with DatabaseConnector::downloadJdbcDrivers(dbms, pathToDriver)

# Details for connecting to the CDM and storing the results
outputFolder <- file.path(getwd(), 'output', databaseId)
cdmDatabaseSchema <- ''
resultsDatabaseSchema <- ''
vocabDatabaseSchema <- cdmDatabaseSchema
oracleTempSchema <- NULL  # For Oracle: define a schema that can be used to emulate temp tables

# An id and name that unique identifies the database
databaseId <- '<required_database_id>'
databaseName <- '<optional_database_name>'
databaseDescription <- '<optional_description>'
authors <- c('', '')
webApiBaseUrl <- ''  # URL to your OHDSI WebAPI that Atlas uses, e.g. http://localhost:8080/WebAPI

# Other settings
smallCellCount <- 5
verboseMode <- TRUE

# Connecting
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = dbms,
  server = server,
  user = user,
  password = password,
  port = port,
  pathToDriver = pathToDriver
)

results <- CdmOnboarding::cdmOnboarding(
 connectionDetails = connectionDetails,
 cdmDatabaseSchema = cdmDatabaseSchema,
 resultsDatabaseSchema = resultsDatabaseSchema,
 vocabDatabaseSchema = vocabDatabaseSchema,
 oracleTempSchema = oracleTempSchema,
 databaseId = databaseId,
 databaseName = databaseName,
 databaseDescription = databaseDescription,
 authors = authors,
 runVocabularyChecks = TRUE,
 runDataTablesChecks = TRUE,
 runPerformanceChecks = TRUE,
 runWebAPIChecks = TRUE,
 smallCellCount = smallCellCount,
 baseUrl = webApiBaseUrl,
 sqlOnly = FALSE,
 outputFolder = outputFolder,
 verboseMode = verboseMode
)

# The following can be used to regenerate the report with the same results:
# generateResultsDocument(
#   results,
#   outputFolder
# )

