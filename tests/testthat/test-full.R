test_that("Full CdmOnboarding executable", {
  results <- do.call(
    CdmOnboarding::cdmOnboarding,
    params
  )

  # Result returned, rds written, docx written.
  testthat::expect_type(results, 'list')
  testthat::expect_length(list.files(params$outputFolder, pattern = '*.rds'), 1)  
  testthat::expect_length(list.files(params$outputFolder, pattern = '*.docx'), 1)  
})
