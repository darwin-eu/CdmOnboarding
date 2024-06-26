# @file DqdChecks.R
#
# Copyright 2023 Darwin EU Coordination Center
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
# @author Maxim Moinat

#' Process dqd file
#' @param dqdJsonPath Path to the DQD JSON file
#' @return list with version, overview, startTimestamp, executionTime
.processDqdResults <- function(dqdJsonPath) {
  ParallelLogger::logInfo("Reading DataQualityDashboard results")
  tryCatch({
    df <- jsonlite::read_json(path = dqdJsonPath, simplifyVector = TRUE)
    dqdResults <- list(
      version = df$Metadata$DQD_VERSION[1],  # if multiple cdm_source records, then there can be multiple DQD versions
      overview = df$Overview,
      startTimestamp = df$startTimestamp,
      executionTime = df$executionTime
    )
    ParallelLogger::logInfo(sprintf("> Successfully extracted DQD results overview from '%s'", dqdJsonPath))
  }, error = function(e) {
    ParallelLogger::logError(sprintf("Could not process dqdJsonPath '%s'", dqdJsonPath))
  })
  return(dqdResults)
}