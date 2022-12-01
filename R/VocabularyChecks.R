# @file VocabularyCheck
#
# Copyright 2022 Darwin EU Coordination Center
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


#' The vocabulary checks (for v5.x)
#'
#' @description
#' \code{vocabularyChecks} runs a list of checks on the vocabulary as part of the CDM Onboarding procedure
#'
#' @details
#' \code{vocabularyChecks} runs a list of checks on the vocabulary as part of the CDM Onboarding procedure
#'
#' @param connectionDetails                An R object of type \code{connectionDetails} created using the function \code{createConnectionDetails} in the \code{DatabaseConnector} package.
#' @param cdmDatabaseSchema    	           Fully qualified name of database schema that contains OMOP CDM schema.
#'                                         On SQL Server, this should specifiy both the database and the schema, so for example, on SQL Server, 'cdm_instance.dbo'.
#' @param vocabDatabaseSchema		           String name of database schema that contains OMOP Vocabulary. Default is cdmDatabaseSchema. On SQL Server, this should specifiy both the database and the schema, so for example 'results.dbo'.
#' @param smallCellCount                   To avoid patient identifiability, cells with small counts (<= smallCellCount) are deleted. Set to NULL if you don't want any deletions.
#' @param sqlOnly                          Boolean to determine if Achilles should be fully executed. TRUE = just generate SQL files, don't actually run, FALSE = run Achilles
#' @param outputFolder                     Path to store logs and SQL files
#' @param dqdJsonPath                      Path to the json of the DQD
#' @param optimize                         Boolean to determine if heuristics will be used to speed up execution. Currently only implemented for postgresql databases. Default = FALSE
#' @return                                 An object of type \code{achillesResults} containing details for connecting to the database containing the results
#' @export
vocabularyChecks <- function (connectionDetails,
                           cdmDatabaseSchema,
                           vocabDatabaseSchema = cdmDatabaseSchema,
                           smallCellCount = 5,
                           sqlOnly = FALSE,
                           outputFolder = "output",
                           dqdJsonPath = NULL,
                           optimize = FALSE) {
  if (optimize && connectionDetails$dbms == "postgresql" ) {
    vocabularyCounts <- executeQuery(outputFolder,"vocabulary_tables_count_postgres.sql", "Count on vocabulary tables (postgres estimate) query executed successfully",
                                     connectionDetails, sqlOnly, vocabDatabaseSchema=vocabDatabaseSchema)
  } else if (optimize && connectionDetails$dbms == "sql server" ) {
    vocabularyCounts <- executeQuery(outputFolder,"vocabulary_tables_count_sql_server.sql", "Count on vocabulary tables (sql server estimate) query executed successfully",
                                     connectionDetails, sqlOnly, vocabDatabaseSchema=vocabDatabaseSchema)
  } else {
    vocabularyCounts <- executeQuery(outputFolder,"vocabulary_tables_count.sql", "Count on vocabulary tables query executed successfully",
                                     connectionDetails, sqlOnly, vocabDatabaseSchema=vocabDatabaseSchema)
  }

  conceptCounts <- executeQuery(outputFolder,"concept_counts_by_vocabulary.sql", "Concept counts by vocabulary query executed successfully",
                                connectionDetails, sqlOnly, vocabDatabaseSchema=vocabDatabaseSchema)
  sourceConceptFrequency <- executeQuery(outputFolder,"source_to_concept_map_frequency.sql", "Source to concept map breakdown query executed successfully",
                                         connectionDetails, sqlOnly, vocabDatabaseSchema=vocabDatabaseSchema)
  sourceConceptMap <- executeQuery(outputFolder,"get_source_to_concept_map.sql", "Source to concept map query executed successfully",
                                   connectionDetails, sqlOnly,vocabDatabaseSchema=vocabDatabaseSchema)

  # Execute in same connection
  # Note: if one query in the tryCatch fails, then all fail ("current transaction is aborted")
  tryCatch({
    connection <- DatabaseConnector::connect(connectionDetails = connectionDetails)
    ParallelLogger::logInfo("Starting vocab mapping queries. Preprocessing domains...")
    mappingTempTableCreation <- executeQuery(outputFolder, "mapping_temp_tables.sql", "Mapping Temp tables query executed successfully", sqlOnly=sqlOnly,
                                                 activeConnection=connection, useExecuteSql=TRUE, cdmDatabaseSchema=cdmDatabaseSchema)
    mappingCompleteness <- executeQuery(outputFolder,"mapping_completeness.sql", "Mapping Completeness query executed successfully", sqlOnly=sqlOnly,
                                            activeConnection=connection)

    drugMapping  <- executeQuery(outputFolder, "mapping_levels_drugs.sql", "Drug Level Mapping query executed successfully", sqlOnly=sqlOnly,
                                     activeConnection=connection, vocabDatabaseSchema=vocabDatabaseSchema)

    unmappedDrugs <- executeQuery(outputFolder, "unmapped_concepts_templated.sql", "Unmapped drugs query executed successfully", sqlOnly=sqlOnly,
                                      activeConnection=connection, cdmDomain='drug', smallCellCount=smallCellCount)
    unmappedConditions <- executeQuery(outputFolder,"unmapped_concepts_templated.sql", "Unmapped conditions query executed successfully", sqlOnly=sqlOnly,
                                           activeConnection=connection, cdmDomain='condition', smallCellCount=smallCellCount)
    unmappedMeasurements <- executeQuery(outputFolder,"unmapped_concepts_templated.sql", "Unmapped measurements query executed successfully", sqlOnly=sqlOnly,
                                             activeConnection=connection, cdmDomain='measurement', smallCellCount=smallCellCount)
    unmappedObservations <- executeQuery(outputFolder,"unmapped_concepts_templated.sql", "Unmapped observations query executed successfully", sqlOnly=sqlOnly,
                                             activeConnection=connection, cdmDomain='observation', smallCellCount=smallCellCount)
    unmappedProcedures <- executeQuery(outputFolder,"unmapped_concepts_templated.sql", "Unmapped procedures query executed successfully", sqlOnly=sqlOnly,
                                           activeConnection=connection, cdmDomain='procedure', smallCellCount=smallCellCount)
    unmappedDevices <- executeQuery(outputFolder,"unmapped_concepts_templated.sql", "Unmapped devices query executed successfully", sqlOnly=sqlOnly,
                                        activeConnection=connection, cdmDomain='device', smallCellCount=smallCellCount)
    unmappedVisits <- executeQuery(outputFolder,"unmapped_concepts_templated.sql", "Unmapped visits query executed successfully", sqlOnly=sqlOnly,
                                       activeConnection=connection, cdmDomain='visit', smallCellCount=smallCellCount)
    unmappedUnitsMeas <- executeQuery(outputFolder,"unmapped_concepts_templated.sql", "Unmapped units query executed successfully", sqlOnly=sqlOnly,
                                          activeConnection=connection, cdmDomain='meas_unit', smallCellCount=smallCellCount)
    unmappedUnitsObs <- executeQuery(outputFolder,"unmapped_concepts_templated.sql", "Unmapped units query executed successfully", sqlOnly=sqlOnly,
                                         activeConnection=connection, cdmDomain='obs_unit', smallCellCount=smallCellCount)
    # todo: merge with domain name
    unmappedUnits <- rbind(unmappedUnitsMeas, unmappedUnitsObs)

    mappedDrugs <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped drugs query executed successfully", sqlOnly=sqlOnly,
                                   activeConnection=connection, cdmDomain='drug', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    mappedConditions <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped conditions query executed successfully", sqlOnly=sqlOnly,
                                         activeConnection=connection , cdmDomain='condition', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    mappedMeasurements <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped measurements query executed successfully", sqlOnly=sqlOnly,
                                           activeConnection=connection , cdmDomain='measurement', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    mappedObservations <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped observations query executed successfully", sqlOnly=sqlOnly,
                                           activeConnection=connection , cdmDomain='observation', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    mappedProcedures <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped procedures query executed successfully", sqlOnly=sqlOnly,
                                         activeConnection=connection  , cdmDomain='procedure', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    mappedDevices <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped devices query executed successfully", sqlOnly=sqlOnly,
                                      activeConnection=connection  , cdmDomain='device', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    mappedVisits <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped visits query executed successfully", sqlOnly=sqlOnly,
                                     activeConnection=connection  , cdmDomain='visit', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    mappedUnitsMeas <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped units query executed successfully", sqlOnly=sqlOnly,
                                        activeConnection=connection  , cdmDomain='meas_unit', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    mappedUnitsObs <- executeQuery(outputFolder,"mapped_concepts_templated.sql", "Mapped units query executed successfully", sqlOnly=sqlOnly,
                                       activeConnection=connection , cdmDomain='obs_unit', vocabDatabaseSchema=vocabDatabaseSchema, smallCellCount=smallCellCount)
    # todo: merge with domain name
    mappedUnits <- rbind(mappedUnitsMeas, mappedUnitsObs)
  },
  finally = {
    DatabaseConnector::disconnect(connection = connection)
    rm(connection)
  })

  list(
    version=conceptCounts$result[conceptCounts$result$ID=='None',]$VERSION,
    mappingTempTableCreation=mappingTempTableCreation,
    mappingCompleteness=mappingCompleteness,
    drugMapping=drugMapping,
    unmappedDrugs=unmappedDrugs,
    unmappedConditions=unmappedConditions,
    unmappedMeasurements=unmappedMeasurements,
    unmappedObservations=unmappedObservations,
    unmappedProcedures=unmappedProcedures,
    unmappedDevices=unmappedDevices,
    unmappedVisits=unmappedVisits,
    unmappedUnits=unmappedUnits,
    mappedDrugs=mappedDrugs,
    mappedConditions=mappedConditions,
    mappedMeasurements=mappedMeasurements,
    mappedObservations=mappedObservations,
    mappedProcedures=mappedProcedures,
    mappedDevices=mappedDevices,
    mappedVisits=mappedVisits,
    mappedUnits=mappedUnits,
    conceptCounts=conceptCounts,
    vocabularyCounts=vocabularyCounts,
    sourceConceptFrequency=sourceConceptFrequency,
    sourceConceptMap=sourceConceptMap
  )
}
