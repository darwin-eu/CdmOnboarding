-- Cross-database solution to get day of the week:
-- * Days after 1900-01-01, which is a Monday
-- * Take modulo 7, add 1
-- * 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
-- * Does not work for dates earlier than 19000101, hence a filter is applied.

SELECT
    'Condition' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', condition_start_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.condition_occurrence
    WHERE condition_start_date >= CAST('19000101' AS DATE)
) condition
GROUP BY day_of_the_week

UNION

SELECT
    'Drug' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', drug_exposure_start_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.drug_exposure
    WHERE drug_exposure_start_date >= CAST('19000101' AS DATE)
) drug
GROUP BY day_of_the_week

UNION

SELECT
    'Procedure' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', procedure_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.procedure_occurrence
    WHERE procedure_date >= CAST('19000101' AS DATE)
) t_procedure
GROUP BY day_of_the_week

UNION

SELECT
    'Measurement' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', measurement_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.measurement
    WHERE measurement_date >= CAST('19000101' AS DATE)
) measurement
GROUP BY day_of_the_week

UNION

SELECT
    'Observation' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', observation_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.observation
    WHERE observation_date >= CAST('19000101' AS DATE)
) observation
GROUP BY day_of_the_week

UNION

SELECT
    'Device' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', device_exposure_start_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.device_exposure
    WHERE device_exposure_start_date >= CAST('19000101' AS DATE)
) device
GROUP BY day_of_the_week

UNION

SELECT
    'Visit' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', visit_start_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.visit_occurrence
    WHERE visit_start_date >= CAST('19000101' AS DATE)
) visit
GROUP BY day_of_the_week

UNION

SELECT
    'Visit Detail' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', visit_detail_start_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.visit_detail
    WHERE visit_detail_start_date >= CAST('19000101' AS DATE)
) visit_detail
GROUP BY day_of_the_week

UNION

SELECT
    'Death' AS domain,
    day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT (DATEDIFF(day, '19000101', death_date)) % 7 + 1 AS day_of_the_week
    FROM @cdmDatabaseSchema.death
    WHERE death_date >= CAST('19000101' AS DATE)
) death
GROUP BY day_of_the_week
;