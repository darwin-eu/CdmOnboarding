#' *******************************************************
#' -----------------INSTRUCTIONS -------------------------
#' *******************************************************
#'
#' -----------------------------------------------------------------------------------------------
#' -----------------------------------------------------------------------------------------------
#' This CodeToRun.R is provided as an example of how to run this package.
#' Below you will find 2 sections: the 1st is for installing the dependencies
#' required to run the package and the 2nd for running the package.
#'
#' The code below makes use of R environment variables (denoted by "Sys.getenv(<setting>)") to
#' allow for protection of sensitive information. If you'd like to use R environment variables stored
#' in an external file, this can be done by creating an .Renviron file in the root of the folder
#' where you have cloned this code. For more information on setting environment variables please refer to:
#' https://stat.ethz.ch/R-manual/R-devel/library/base/html/readRenviron.html
#'
#' Below is an example .Renviron file's contents:
#'    DBMS = "postgresql"
#'    DB_SERVER = "database.server.com"
#'    DB_PORT = 5432
#'    DB_USER = "database_user_name_goes_here"
#'    DB_PASSWORD = "your_secret_password"
#'    PATH_TO_DRIVER = "/dbms/driver/folder"
#'    CDM_SCHEMA = "your_cdm_schema"
#'    RESULTS_SCHEMA = "your_achilles_results_schema"
#'
#' The settings are described in detail on http://ohdsi.github.io/DatabaseConnector/
#'
#' Once you have established an .Renviron file, you must restart your R session for R to pick up these new
#' variables.
#'
#' Alternatively, enter the parameters directly in this file, replacing the 'Sys.getenv' calls.
#'
#' In section 2 below, you will also need to update the code to use your site specific values. Please scroll
#' down for specific instructions.

#' *******************************************************
#' SECTION 1: Install latest version of CdmOnboarding
#' *******************************************************
#' Install CdmOnboarding using remotes. Alternatively devtools can be used.
#' When asked to update packages, select '1' ('update all') (could be multiple times)
#' When asked whether to install from source, select 'No' (could be multiple times)
if (!require(CdmOnboarding)) {
  remotes::install_github("DARWIN-EU/CdmOnboarding")
}

# *******************************************************
# SECTION 2: Set Local Details
# *******************************************************
library(CdmOnboarding)
library(Achilles)
library(DashboardExport)
remotes::install_github('darwin-eu/DashboardExport')

achilles(
  connectionDetails,
  cdmDatabaseSchema,
  resultsDatabaseSchema = cdmDatabaseSchema,
  scratchDatabaseSchema = resultsDatabaseSchema,
  vocabDatabaseSchema = cdmDatabaseSchema,
  tempEmulationSchema = resultsDatabaseSchema,
  createTable = TRUE,
  smallCellCount = 5,
  cdmVersion = "5.4",
  createIndices = TRUE,
  numThreads = 1,
  tempAchillesPrefix = "tmpach",
  dropScratchTables = TRUE,
  sqlOnly = FALSE,
  outputFolder = "output",
  verboseMode = TRUE,
  optimizeAtlasCache = FALSE,
  defaultAnalysesOnly = FALSE,
  updateGivenAnalysesOnly = FALSE,
  sqlDialect = NULL
)

# fill out the connection details -----------------------------------------------------------------------
dbms <- 'postgresql' # Sys.getenv("DBMS")
user <- 'postgres' # Sys.getenv("DB_USER")
password <- 'postgres' # Sys.getenv("DB_PASSWORD")
server <- 'localhost/cpath_lgs' # Sys.getenv("DB_SERVER")
port <- 5432 # Sys.getenv("DB_PORT")
pathToDriver <- 'C:\\Program Files\\JDBC' # Sys.getenv("PATH_TO_DRIVER")
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = dbms,
  server = server,
  port = port,
  user = user,
  password = password,
  pathToDriver = pathToDriver
)

# Details for connecting to the CDM
cdmDatabaseSchema <- 'cdm' # Sys.getenv("CDM_SCHEMA")
resultsDatabaseSchema <- 'results' # Sys.getenv("RESULTS_SCHEMA")
# vocabDatabaseSchema <- 'vocab' #cdmDatabaseSchema
oracleTempSchema <- NULL

# Details specific to the database:
databaseId <- 'Test' # Sys.getenv("DATABASE_ID")
authors <- c('Annetje') # used on the title page

# URL to the WebAPI that your local Atlas instance uses, e.g. http://localhost:8080/WebAPI
baseUrl <- 'http://localhost:8080/WebAPI' # Sys.getenv("WEBAPI_BASEURL")

# (optional) Path to your DQD results file
dqdJsonPath <- 'extras/example_input/dqd_synthea20k.json'

outputFolder <- file.path(getwd(), "output", databaseId)
smallCellCount <- 5
verboseMode <- TRUE

# *******************************************************
# SECTION 3: Run the package
# *******************************************************
results <- CdmOnboarding::cdmOnboarding(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  resultsDatabaseSchema = resultsDatabaseSchema,
  vocabDatabaseSchema = cdmDatabaseSchema,
  oracleTempSchema = oracleTempSchema,
  databaseId = databaseId,
  authors = authors,
  smallCellCount = smallCellCount,
  outputFolder = outputFolder,
)

# cdmOnboarding() should already generate the resultsdocument.
# Use this to regenerate upon error (results object should be returned anyway)
if (FALSE) {
  CdmOnboarding::generateResultsDocument(
    results = results,
    outputFolder = outputFolder,
    authors = authors
  )
}
