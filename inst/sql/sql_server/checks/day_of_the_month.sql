SELECT
    'Condition' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(condition_start_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.condition_occurrence
) condition
GROUP BY day_of_the_month

UNION

SELECT
    'Drug' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(drug_exposure_start_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.drug_exposure 
) drug
GROUP BY day_of_the_month

UNION

SELECT
    'Procedure' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(procedure_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.procedure_occurrence 
) t_procedure
GROUP BY day_of_the_month

UNION

SELECT
    'Measurement' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(measurement_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.measurement 
) measurement
GROUP BY day_of_the_month

UNION

SELECT
    'Observation' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(observation_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.observation 
) observation
GROUP BY day_of_the_month

UNION

SELECT
    'Device' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(device_exposure_start_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.device_exposure 
) device
GROUP BY day_of_the_month

UNION

SELECT
    'Visit' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(visit_start_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.visit_occurrence
) visit
GROUP BY day_of_the_month

UNION

SELECT
    'Visit Detail' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(visit_detail_start_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.visit_detail
) visit_detail
GROUP BY day_of_the_month

UNION

SELECT
    'Death' AS domain,
    day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM (
    SELECT day(death_date) AS day_of_the_month
    FROM @cdmDatabaseSchema.death
) death
GROUP BY day_of_the_month
;
