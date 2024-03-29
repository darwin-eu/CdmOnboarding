% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/DataTablesChecks.R
\name{dataTablesChecks}
\alias{dataTablesChecks}
\title{The Data Tables checks (for v5.x)}
\usage{
dataTablesChecks(
  connectionDetails,
  cdmDatabaseSchema,
  resultsDatabaseSchema,
  cdmVersion,
  sqlOnly = FALSE,
  outputFolder = "output",
  optimize = FALSE
)
}
\arguments{
\item{connectionDetails}{An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.}

\item{cdmDatabaseSchema}{Fully qualified name of database schema that contains OMOP CDM schema.
On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.}

\item{resultsDatabaseSchema}{Fully qualified name of database schema that we can write final results to.
On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_results.dbo'.}

\item{cdmVersion}{Define the OMOP CDM version used: currently supports v5 and above.
Use major release number or minor number only (e.g. 5, 5.3)}

\item{sqlOnly}{Boolean to determine if Achilles should be fully executed. TRUE = just generate SQL files, don't actually run, FALSE = run Achilles}

\item{outputFolder}{Path to store logs and SQL files}

\item{optimize}{Boolean to determine if heuristics will be used to speed up execution. Currently only implemented for postgresql databases. Default = FALSE}
}
\value{
\if{html}{\out{<div class="sourceCode">}}\preformatted{                            An object of type \code{achillesResults} containing details for connecting to the database containing the results
}\if{html}{\out{</div>}}
}
\description{
\code{dataTablesChecks} runs a list of checks on the clinical data tables as part of the CDM Onboarding procedure
}
\details{
\code{dataTablesChecks} runs a list of checks on the clinical data tables as part of the CDM Onboarding procedure
}
