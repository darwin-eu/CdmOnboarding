test_that("Observation Period Overlap Query", {
    library(duckdb)
    con <- DBI::dbConnect(duckdb::duckdb(), ":memory:")

    query <- "CREATE TABLE observation_period (
        observation_period_id INT,
        person_id INT,
        observation_period_start_date DATE,
        observation_period_end_date DATE);"
    dbExecute(con, query)

    query <- "INSERT INTO observation_period (observation_period_id, person_id, observation_period_start_date, observation_period_end_date)
              VALUES 
                (1, 1, '2020-01-01', '2020-12-01'),
                (2, 1, '2020-06-01', '2021-05-01'),
                (3, 1, '2019-06-01', '2022-05-01'),
                (4, 2, '2019-08-01', '2020-04-01'),
                (5, 2, '2020-01-01', '2020-12-01'),
                (6, 2, '2020-03-01', '2021-01-01'),
                (7, 3, '2020-01-01', '2020-12-01'),
                (8, 3, '2020-06-01', '2020-07-01'),
                (9, 3, '2021-01-01', '2021-12-01'),
                (10, 4, '2019-01-01', '2019-12-01'),
                (11, 4, '2019-10-01', '2019-12-01'),
                (12, 4, '2021-08-01', '2021-12-01'),
                (13, 4, '2021-11-01', '2022-03-01'),
                (14, 5, '2019-01-01', '2019-12-01'),
                (15, 5, '2020-01-01', '2020-12-01')
                ;"
    dbExecute(con, query)

    # Run observation_period_overlap.sql
    query <- paste(readLines("inst/sql/sql_server/checks/observation_period_overlap.sql"), collapse = "\n")
    gsub('@cdmDatabaseSchema.', '', query)
    result <- DBI::dbGetQuery(con, query)

    # Expected output (person_id, overlap_count):
    # 1 3 --> all three completely overlap with each other, creating 3 overlapping pairs
    # 2 3 --> all three partially overlap, three pairs
    # 3 1 --> only one overlapping pair
    # 4 2 --> two overlapping pairs
    # (person_id 5 not included because it has no overlap)
    testthat::expect_equal(result[result$person_id == 1, 2], 3, info = "person_id 1 should have 3 overlapping pairs")
    testthat::expect_equal(result[result$person_id == 2, 2], 3, info = "person_id 2 should have 3 overlapping pairs")
    testthat::expect_equal(result[result$person_id == 3, 2], 1, info = "person_id 3 should have 1 overlapping pairs")
    testthat::expect_equal(result[result$person_id == 4, 2], 2, info = "person_id 4 should have 2 overlapping pairs")
    testthat::expect_equal(nrow(result[result$person_id == 5, ]), 0, info = "person_id 5 should have no overlapping pairs")

    dbDisconnect(con)
}