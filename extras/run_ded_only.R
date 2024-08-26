library(DBI)
library(RPostgres)
library(CDMConnector)
library(DrugExposureDiagnostics)

# Connecting using dsn, to be set up in database driver
con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = Sys.getenv("CDM5_POSTGRESQL_DBNAME"),
                      host = Sys.getenv("CDM5_POSTGRESQL_HOST"),
                      user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                      password = Sys.getenv("CDM5_POSTGRESQL_PASSWORD"))

cdm <- cdm_from_con(con,
                    cdm_schema = Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA"),
                    write_schema = Sys.getenv("CDM5_POSTGRESQL_SCRATCH_SCHEMA"))

ded_start_time <- Sys.time()

dedResults <- DrugExposureDiagnostics::executeChecks(
  cdm = cdm,
  ingredients = c(
    528323,
    954688,
    968426,
    1119119,
    1125315,
    1139042,
    1140643,
    1154343,
    1550557,
    1703687,
    40225722
  ),
  checks = c("missing", "exposureDuration", "type", "route", "dose", "quantity", "diagnosticsSummary"),
  minCellCount = 5,
  sample = 1e+06,
  earliestStartDate = "2010-01-01"
)

duration <- as.numeric(difftime(Sys.time(), ded_start_time), units = "secs")
dedVersion <- packageVersion(pkg = "DrugExposureDiagnostics")
dedSummary <- list(result = dedResults$diagnosticsSummary, duration = duration, packageVersion = dedVersion)
saveRDS(dedSummary, "dedSummary.rds")