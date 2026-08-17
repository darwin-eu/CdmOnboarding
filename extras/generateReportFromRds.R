# This takes the rds file stored in given path, and writes the docx report to the same path
rds <- readline("Enter the path where CdmOnboarding results are: ")
results <- readRDS(rds)
authors <- c('-')

# Optional, add separate DED results
rds_ded <- readline("Enter the path for DED file: ")
ded_results <- readRDS(rds_ded)
results$drugExposureDiagnostics <- ded_results

if (FALSE) {
  options(error = browser)
  # remotes::install_github('darwin-eu/cdmonboarding', ref='3.3.4')
  devtools::install(quick = TRUE, upgrade = 'never')
  devtools::reload()
  devtools::load_all()
}
# Optional, make compatible with current version
source('extras/compat.R')
results <- compat(results, fixCasing = FALSE)

CdmOnboarding::generateResultsDocument(
  results = results,
  outputFolder = dirname(rds),
  authors = authors
)

# Generate csv for Portal reports
CdmOnboarding::exportDedResults(results, outputFolder = path)
CdmOnboarding::exportPerformanceBenchmark(results, outputFolder = path)


# Plot regeneration -----
library(tidyverse)
source('R/Figures.R')
print(results$databaseId)

.recordsCountPlot(results$dataTablesResults$totalRecords$result, log_y_axis = F)
.recordsCountPlot(results$dataTablesResults$recordsPerPerson$result, log_y_axis = F)

.heatMapPlot(results$dataTablesResults$dayOfTheWeek$result, 'DAY_OF_THE_WEEK')
.heatMapPlot(results$dataTablesResults$dayOfTheMonth$result, 'DAY_OF_THE_MONTH')

# Select or remove a domain to recalibrate colour scale
results$dataTablesResults$dayOfTheWeek$result %>%
  dplyr::filter(DOMAIN != 'Measurement') %>%
  .heatMapPlot('DAY_OF_THE_WEEK')

results$dataTablesResults$dayOfTheMonth$result %>%
  dplyr::filter(DOMAIN %in% c('Death', 'Drug')) %>%
  .heatMapPlot('DAY_OF_THE_MONTH')


results$dataTablesResults