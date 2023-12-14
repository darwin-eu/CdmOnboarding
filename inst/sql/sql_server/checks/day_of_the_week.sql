-- Cross-database solution to get day of the week:
-- * Days after 1900-01-01, which is a Monday
-- * Take modulo 7, add 1
-- * 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
-- * Does not work for dates earlier than 19000101, hence a filter is applied.

SELECT
    'Condition' AS domain,
    (DATEDIFF(day, '19000101', condition_start_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.condition_occurrence
WHERE condition_start_date >= CAST('19000101' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Drug' AS domain,
    (DATEDIFF(day, '19000101', drug_exposure_start_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.drug_exposure
WHERE drug_exposure_start_date >= CAST('19000101' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Procedure' AS domain,
    (DATEDIFF(day, '19000101', procedure_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.procedure_occurrence
WHERE procedure_date >= CAST('19000101' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Measurement' AS domain,
    (DATEDIFF(day, '19000101', measurement_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.measurement
WHERE measurement_date >= CAST('19000101' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Observation' AS domain,
    (DATEDIFF(day, '19000101', observation_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.observation
WHERE observation_date >= CAST('19000101' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Device' AS domain,
    (DATEDIFF(day, '19000101', device_exposure_start_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.device_exposure
WHERE device_exposure_start_date >= CAST('19000101' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Visit' AS domain,
    (DATEDIFF(day, '19000101', visit_start_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.visit_occurrence
WHERE visit_start_date >= CAST('19000101' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Visit Detail' AS domain,
    (DATEDIFF(day, '19000101', visit_detail_start_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.visit_detail
WHERE visit_detail_start_date >= CAST('19000101' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Death' AS domain,
    (DATEDIFF(day, '19000101', death_date)) % 7 + 1 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.death
WHERE death_date >= CAST('19000101' AS DATE)
GROUP BY 1,2
;
