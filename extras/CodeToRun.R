# *******************************************************
# -----------------INSTRUCTIONS -------------------------
# *******************************************************
#
#-----------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------
# This CodeToRun.R is provided as an example of how to run this package.
# Below you will find 2 sections: the 1st is for installing the dependencies
# required to run the package and the 2nd for running the package.
#
# The code below makes use of R environment variables (denoted by "Sys.getenv(<setting>)") to
# allow for protection of sensitive information. If you'd like to use R environment variables stored
# in an external file, this can be done by creating an .Renviron file in the root of the folder
# where you have cloned this code. For more information on setting environment variables please refer to:
# https://stat.ethz.ch/R-manual/R-devel/library/base/html/readRenviron.html
#
# Below is an example .Renviron file's contents:
#    DBMS = "postgresql"
#    DB_SERVER = "database.server.com"
#    DB_PORT = 5432
#    DB_USER = "database_user_name_goes_here"
#    DB_PASSWORD = "your_secret_password"
#    PATH_TO_DRIVER = "/dbms/driver/folder"
#    CDM_SCHEMA = "your_cdm_schema"
#    RESULTS_SCHEMA = "your_achilles_results_schema"
#
# The settings are described in detail on http://ohdsi.github.io/DatabaseConnector/
#
# Once you have established an .Renviron file, you must restart your R session for R to pick up these new
# variables.
#
# In section 2 below, you will also need to update the code to use your site specific values. Please scroll
# down for specific instructions.
#-----------------------------------------------------------------------------------------------
#
# *******************************************************
# SECTION 1: Install latest version of CdmOnboarding
# *******************************************************
#
# Prevents errors due to packages being built for other R versions:
Sys.setenv("R_REMOTES_NO_ERRORS_FROM_WARNINGS" = TRUE)

# Install CdmOnboarding using remotes. Alternatively devtools can be used.
# When asked to update packages, select '1' ('update all') (could be multiple times)
# When asked whether to install from source, select 'No' (could be multiple times)
if(!require(CdmOnboarding)){
  remotes::install_github("Darwin-eu/CdmOnboarding")
}

# *******************************************************
# SECTION 2: Set Local Details
# *******************************************************
library(CdmOnboarding)

# Details for connecting to the server:
dbms <- Sys.getenv("DBMS")
user <- if (Sys.getenv("DB_USER") == "") NULL else Sys.getenv("DB_USER")
password <- if (Sys.getenv("DB_PASSWORD") == "") NULL else Sys.getenv("DB_PASSWORD")
server <- Sys.getenv("DB_SERVER")
port <- Sys.getenv("DB_PORT")
pathToDriver <- Sys.getenv("PATH_TO_DRIVER") # Driver can be installed with DatabaseConnector::downloadJdbcDrivers(dbms, pathToDriver)

# Details for connecting to the CDM and storing the results
cdmDatabaseSchema <- Sys.getenv("CDM_SCHEMA")
vocabDatabaseSchema <- cdmDatabaseSchema # If different from CDM schema
resultsDatabaseSchema <- Sys.getenv("RESULTS_SCHEMA") # Make sure the Achilles results are in this schema

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

# Details specific to the database:
databaseId <- '<required_database_id>'
databaseName <- '<optional_database_name>'
databaseDescription <- '<optional_description>'
authors <- c('<author_1>', '<author_2>') # used on the title page

# Output
outputFolder <- file.path(getwd(), "results", databaseId)

# Url to check the version of your local Atlas
baseUrl <- "<your_baseUrl>" # URL to your OHDSI WebAPI that Atlas uses, e.g. http://localhost:8080/WebAPI

# All results smaller than this value are removed from the results.
smallCellCount <- 5
verboseMode <- TRUE

# Optimization
optimize <- TRUE  # For postgresql only, for efficient data tables count estimates.
dqdJsonPath <- ''  # (optional) Path to your DQD results file

# *******************************************************
# SECTION 3: Run the package
# *******************************************************

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
  baseUrl = baseUrl,
  sqlOnly = FALSE,
  outputFolder = outputFolder,
  verboseMode = verboseMode,
  dqdJsonPath = dqdJsonPath,
  optimize = optimize
)

# The results document should already have been generated. Use this to regenerate upon error in cdmOnboarding
# CdmOnboarding::generateResultsDocument(
#   results,
#   outputFolder,
#   authors
# )
