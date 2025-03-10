library(DBI)
library(RPostgres)
library(CDMConnector)
library(DrugExposureDiagnostics)
library(CdmOnboarding)

# More DBI examples: https://darwin-eu.github.io/CDMConnector/articles/a04_DBI_connection_examples.html
con <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("CDM5_POSTGRESQL_DBNAME"),
  host = Sys.getenv("CDM5_POSTGRESQL_HOST"),
  user = Sys.getenv("CDM5_POSTGRESQL_USER"),
  password = Sys.getenv("CDM5_POSTGRESQL_PASSWORD")
)

cdm <- cdmFromCon(
  con,
  cdmSchema = Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA"),
  writeSchema = Sys.getenv("CDM5_POSTGRESQL_SCRATCH_SCHEMA"),
  .softValidation = TRUE
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