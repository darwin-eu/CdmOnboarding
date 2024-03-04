# This takes the rds file stored in given path, and writes the docx report to the same path
path <- getwd()

rds <- list.files(path, '.rds')
results <- readRDS(file.path(path, rds))
authors <- c('-')

# Optional, add separate DED results
path_ded <- readline("Enter the path for DED file: ")
results$drugExposureDiagnostics <- ded_results

# Optional, make compatible with current version
results <- CdmOnboarding::compat(results)

# options(error = default)
# devtools::reload()
CdmOnboarding::generateResultsDocument(
    results = results,
    outputFolder = path,
    authors = authors
)
