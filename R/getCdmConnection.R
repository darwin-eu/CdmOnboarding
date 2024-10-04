  # @file executeQuery.R
#
# Copyright 2024 Darwin EU Coordination Center
#
# This file is part of CdmOnboarding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @author Darwin EU Coordination Center
# @author Peter Rijnbeek
# @author Maxim Moinat

#' Convenience function to get a CDMConnector connection from connectionDetails
#' @param connectionDetails An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema Fully qualified name of database schema that contains OMOP CDM schema.
#'                          On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param scratchDatabaseSchema Fully qualified name of database schema where temporary tables can be written.
#' @returns CDMConnector connection
.getCdmConnection <- function(
  connectionDetails,
  cdmDatabaseSchema,
  scratchDatabaseSchema)
{
  # Connect to the database. For postgres with DBI if RPostgres installed, otherwise via DatabaseConnector.
  if (connectionDetails$dbms == 'postgresql' && system.file(package = 'RPostgres') != '') {
    server_parts <- strsplit(connectionDetails$server(), "/")[[1]]

    connection <- DBI::dbConnect(
      RPostgres::Postgres(),
      dbname = server_parts[2],
      host = server_parts[1],
      user = connectionDetails$user(),
      password = connectionDetails$password()
    )
  } else {
    connection <- DatabaseConnector::connect(connectionDetails)
  }
  return(connection)
}