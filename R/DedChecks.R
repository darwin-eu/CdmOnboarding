#' Run DrugExposureDiagnostics for a set of default ingredient concepts
.runDedChecks <- function(
    connectionDetails,
    cdmDatabaseSchema
) {
    dedIngredientIds <- getDedIngredientIds()

    ParallelLogger::logInfo(sprintf(
        "Starting execution of DrugExposureDiagnostics for %s ingredients...",
        length(dedIngredientIds)
    ))

    ded_start_time <- Sys.time()
    tryCatch({
        connection <- DatabaseConnector::connect(connectionDetails)
        cdm <- CDMConnector::cdm_from_con(connection, cdm_schema = cdmDatabaseSchema)
        # Reduce output lines by suppressing both warnings and messages. Only progress bars displayed.
        suppressWarnings(suppressMessages(
          dedResults <- DrugExposureDiagnostics::executeChecks(
            cdm = cdm,
            ingredients = dedIngredientIds,
            checks = c("exposureDuration", "type", "route", "dose", "quantity"),
            minCellCount = 5,
            sample = 1e+06,
            earliestStartDate = "2010-01-01"
          )
        ))
        duration <- as.numeric(difftime(Sys.time(), ded_start_time), units = "secs")
        drugExposureDiagnostics <- list(result = dedResults$diagnostics_summary, duration = duration)
        ParallelLogger::logInfo(sprintf("Executing DrugExposureDiagnostics took %.2f seconds.", duration))
        dedResults
      },
      error = function(e) {
        ParallelLogger::logError("Execution of DrugExposureDiagnostics failed: ", e)
        NULL
      },
      finally = {
        DatabaseConnector::disconnect(connection)
        rm(connection)
      }
    )
}

#' Returns concept_ids for drug ingredients used for DrugExposureDiagnostics check
#' @export
getDedIngredientIds <- function() {
     dedIngredientIds <- c(1125315, 1139042, 1703687, 1119119, 1154343,
                           528323, 954688, 968426, 1550557, 1140643, 40225722)
    return(dedIngredientIds)
}