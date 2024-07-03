library(testthat)
library(CdmOnboarding)

setwd('tests/testthat')
options(warn = -1)

# Individual tests
# devtools::install(quick = TRUE, upgrade = 'never')
# devtools::reload()

testthat::test_file('test-dataTablesChecks.R')
testthat::test_file('test-dataTablesChecksOptimize.R')

testthat::test_file('test-vocabularyChecks.R')
testthat::test_file('test-vocabularyChecksOptimize.R')

testthat::test_file('test-dedChecks.R')

testthat::test_file('test-performanceChecks.R')

testthat::test_file('test-webapiChecks.R')

testthat::test_file('test-dqdJsonPath.R')

testthat::test_file('test-no_checks.R')

testthat::test_file('test-full.R')
