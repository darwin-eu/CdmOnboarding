SELECT 
    'Condition' AS domain,
    day(condition_start_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.condition_occurrence 
GROUP BY 1,2
UNION
SELECT 
    'Drug' AS domain,
    day(drug_exposure_start_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.drug_exposure 
GROUP BY 1,2
UNION
SELECT 
    'Procedure' AS domain,
    day(procedure_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.procedure_occurrence 
GROUP BY 1,2
UNION
SELECT 
    'Measurement' AS domain,
    day(measurement_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.measurement 
GROUP BY 1,2
UNION
SELECT 
    'Observation' AS domain,
    day(observation_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.observation 
GROUP BY 1,2
UNION
SELECT 
    'Device' AS domain,
    day(device_exposure_start_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.device_exposure 
GROUP BY 1,2
UNION
SELECT 
    'Visit' AS domain,
    day(visit_start_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.visit_occurrence
GROUP BY 1,2
UNION
SELECT 
    'Visit Detail' AS domain,
    day(visit_detail_start_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.visit_detail
GROUP BY 1,2
UNION
SELECT 
    'Death' AS domain,
    day(death_date) AS day_of_the_month,
    COUNT_BIG(*) AS n_records
FROM @cdmDatabaseSchema.death
GROUP BY 1,2