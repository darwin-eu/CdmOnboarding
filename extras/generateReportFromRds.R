# This takes the rds file stored in given path, and writes the docx report to the same path
path <- getwd()

rds <- list.files(path, '.rds')
results <- readRDS(file.path(path, rds))
authors <- c('-')

# options(error = browser)
CdmOnboarding::generateResultsDocument(
    results = results,
    outputFolder = path,
    authors = authors
)
