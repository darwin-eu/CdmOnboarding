-- Cross-database solution to get day of the week:
-- * Days after 1900-01-01, which is a Monday
-- * Take modulo 7
-- * 0 = Monday, 1 = Tuesday, ..., 6 = Sunday
-- * Does not work for dates earlier than 1900-01-01, hence a filter is applied.

SELECT
    'Condition' as domain,
    (condition_start_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm.condition_occurrence
WHERE condition_start_date >= ('1900-01-01'::date)
GROUP BY 1,2

UNION

SELECT
    'Drug' as domain,
    (drug_exposure_start_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm.drug_exposure
WHERE drug_exposure_start_date >= ('1900-01-01'::date)
GROUP BY 1,2

UNION

SELECT
    'Procedure' as domain,
    (procedure_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm.procedure_occurrence
WHERE procedure_date >= ('1900-01-01'::date)
GROUP BY 1,2

UNION

SELECT
    'Measurement' as domain,
    (measurement_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm.measurement
WHERE measurement_date >= ('1900-01-01'::date)
GROUP BY 1,2

UNION

SELECT
    'Observation' as domain,
    (observation_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm.observation
WHERE observation_date >= ('1900-01-01'::date)
GROUP BY 1,2

UNION

SELECT
    'Device' as domain,
    (device_exposure_start_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm.device_exposure
WHERE device_exposure_start_date >= ('1900-01-01'::date)
GROUP BY 1,2

UNION

SELECT
    'Visit' as domain,
    (visit_start_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm.visit_occurrence
WHERE visit_start_date >= ('1900-01-01'::date)
GROUP BY 1,2

UNION

SELECT
    'Visit Detail' as domain,
    (visit_detail_start_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm.visit_detail
WHERE visit_detail_start_date >= ('1900-01-01'::date)
GROUP BY 1,2

UNION

SELECT
    'Death' as domain,
    (death_date - '1900-01-01'::date) % 7 AS day_of_the_week,
    COUNT(*)
FROM cdm_synpuf1k.death
WHERE death_date >= ('1900-01-01'::date)
GROUP BY 1,2
;
