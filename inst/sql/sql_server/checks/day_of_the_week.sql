-- Cross-databASe solution to get day of the week:
-- * Days after 1900-01-01, which is a Monday
-- * Take modulo 7
-- * 0 = Monday, 1 = Tuesday, ..., 6 = Sunday
-- * Does not work for dates earlier than 1900-01-01, hence a filter is applied.

SELECT
    'Condition' AS domain,
    DATEDIFF(day, '1900-01-01', condition_start_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.condition_occurrence
WHERE condition_start_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Drug' AS domain,
    DATEDIFF(day, '1900-01-01', drug_exposure_start_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.drug_exposure
WHERE drug_exposure_start_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Procedure' AS domain,
    DATEDIFF(day, '1900-01-01', procedure_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.procedure_occurrence
WHERE procedure_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'MeASurement' AS domain,
    DATEDIFF(day, '1900-01-01', meASurement_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.meASurement
WHERE meASurement_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Observation' AS domain,
    DATEDIFF(day, '1900-01-01', observation_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.observation
WHERE observation_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Device' AS domain,
    DATEDIFF(day, '1900-01-01', device_exposure_start_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.device_exposure
WHERE device_exposure_start_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Visit' AS domain,
    DATEDIFF(day, '1900-01-01', visit_start_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.visit_occurrence
WHERE visit_start_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Visit Detail' AS domain,
    DATEDIFF(day, '1900-01-01', visit_detail_start_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.visit_detail
WHERE visit_detail_start_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2

UNION

SELECT
    'Death' AS domain,
    DATEDIFF(day, '1900-01-01', death_date) % 7 AS day_of_the_week,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.death
WHERE death_date >= CAST('1900-01-01' AS DATE)
GROUP BY 1,2
;
