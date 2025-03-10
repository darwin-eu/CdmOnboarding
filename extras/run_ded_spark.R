library(DBI)
library(odbc)
library(CDMConnector)
library(DrugExposureDiagnostics)

# Connecting using dsn, to be set up in database driver
con <- DBI::dbConnect(odbc::odbc(), "<your_spark_dsn>")

# Or using user/password/server:
# con <- DBI::dbConnect(odbc::odbc(),
#                       Driver   = "<name of the downloaded driver>",
#                       Server   = "<your_spark_server>",
#                       UID      = "<your_spark_user>",
#                       PWD      = "<your_spark_user_password>",
#                       Port     = 1433)

cdm <- CDMConnector::cdmFromCon(
  con,
  cdmSchema = "<your_cdm_schema>",
  writeSchema =  "<your_results_schema>"
)

ded_start_time <- Sys.time()
dedIngredients <- CdmOnboarding::getDedIngredients()
dedResults <- DrugExposureDiagnostics::executeChecks(
  cdm = cdm,
  ingredients = dedIngredients$concept_id,
  checks = c("missing", "exposureDuration", "type", "route", "dose", "quantity", "diagnosticsSummary"),
  minCellCount = 5,
  sample = NULL,
  earliestStartDate = "2005-01-01"
)
duration <- as.numeric(difftime(Sys.time(), ded_start_time), units = "secs")
CDMConnector::cdmDisconnect(cdm)

mappingLevels <- CdmOnboarding::getMappingLevel(dedResults)

dedSummary <- list(
  result = dedResults$diagnosticsSummary,
  resultMappingLevel = mappingLevels,
  duration = duration,
  packageVersion = packageVersion(pkg = "DrugExposureDiagnostics")
)

outputPath <- './'

saveRDS(dedSummary, file.path(outputPath, "dedSummary.rds"))
exportDedResults(outputPath)