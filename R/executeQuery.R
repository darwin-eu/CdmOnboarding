
executeQuery <- function(
  outputFolder,
  sqlFileName,
  successMessage = NULL,
  connectionDetails = NULL,
  sqlOnly = FALSE,
  activeConnection = NULL,
  useExecuteSql = FALSE,
  ...) {
  if (!is.null(connectionDetails)) {
    dbms <- connectionDetails$dbms
  } else {
    dbms <- activeConnection@dbms
  }

  if (is.null(successMessage)) {
    successMessage <- sprintf("'%s' executed successfully", sqlFileName)
  }

  sql <- do.call(
    SqlRender::loadRenderTranslateSql,
    c(
      sqlFilename = file.path("checks", sqlFileName),
      packageName = "CdmOnboarding",
      dbms = dbms,
      warnOnMissingParameters = FALSE,
      list(...)
    )
  )

  duration <- -1
  result <- NULL
  if (sqlOnly) {
    SqlRender::writeSql(sql = sql, targetFile = file.path(outputFolder, sqlFileName))
    return(list(result = result, duration = duration))
  }

  errorReportFile <- file.path(outputFolder, sprintf("%sErr.txt", tools::file_path_sans_ext(sqlFileName)))
  tryCatch({
    start_time <- Sys.time()

    if (is.null(activeConnection)) {
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    } else {
      connection <- activeConnection
    }

    if (useExecuteSql) {
      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql,
        errorReportFile = errorReportFile,
        reportOverallTime = FALSE
      )
    } else {
      result <- DatabaseConnector::querySql(
        connection = connection,
        sql = sql,
        errorReportFile = errorReportFile
      )
    }

    duration <- as.numeric(difftime(Sys.time(), start_time), units = "secs")
    ParallelLogger::logInfo(sprintf("> %s in %.2f secs", successMessage, duration))
  },
  error = function(e) {
    ParallelLogger::logError(sprintf("%s", e))
    ParallelLogger::logError(sprintf("> Query failed. See '%s' for more details", errorReportFile))
  },
  finally = {
    if (is.null(activeConnection)) {
      DatabaseConnector::disconnect(connection = connection)
      rm(connection)
    }
  })

  return(list(result = result, duration = duration))
}
