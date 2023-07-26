#' Run DrugExposureDiagnostics for a set of default ingredient concepts
.runDedChecks <- function(
    connectionDetails,
    cdmDatabaseSchema
) {
    dedIngredients <- getDedIngredients()
    dedIngredientIds <- dedIngredients$concept_id

    ParallelLogger::logInfo(sprintf(
        "Starting execution of DrugExposureDiagnostics for %s ingredients",
        length(dedIngredientIds)
    ))

    tryCatch({
        connection <- DatabaseConnector::connect(connectionDetails)
        cdm <- CDMConnector::cdm_from_con(connection, cdm_schema = cdmDatabaseSchema)

        ded_start_time <- Sys.time()

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
        ParallelLogger::logInfo(sprintf("Executing DrugExposureDiagnostics took %.2f seconds.", duration))
        # Return result with duration
        list(result = dedResults$diagnostics_summary, duration = duration)
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

#' Returns data frame with concept_id and concept_name of drug ingredients
#' used for the DrugExposureDiagnostics check
#' @export
getDedIngredients <- function() {
  dedIngredients <- data.frame(
    concept_id = c(
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
    concept_name = c(
      "hepatitis B surface antigen vaccine",
      "latanoprost",
      "mesalamine",
      "adalimumab",
      "acetaminophen",
      "acetylcysteine",
      "sumatriptan",
      "albuterol",
      "prednisolone",
      "acyclovir",
      "ulipristal"
    )
  )
  return(dedIngredients)
}