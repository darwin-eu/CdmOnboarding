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

cdm <- CDMConnector::cdm_from_con(
                    con, 
                    cdm_schema = "<your_cdm_schema>", 
                    write_schema =  "<your_results_schema>")

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
                        40225722),
            checks = c("exposureDuration", "type", "route", "dose", "quantity", "diagnosticsSummary"),
            minCellCount = 5,
            sample = 1e+06,
            earliestStartDate = "2010-01-01"
          )

duration <- as.numeric(difftime(Sys.time(), ded_start_time), units = "secs")
dedSummary <- list(result = dedResults$diagnosticsSummary, duration = duration)
saveRDS(dedSummary, "dedSummary.rds")