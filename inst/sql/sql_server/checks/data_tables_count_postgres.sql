-- Estimate of cdm table counts
SELECT
    c.relname AS tablename,
    c.reltuples::bigint as count,
    NULL as "person count"
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r'
  and nspname = '@cdmDatabaseSchema'
  and upper(relname) in (
  'CARE_SITE', 'CDM_SOURCE', 'COHORT', 'COHORT_ATTRIBUTE', 'CONDITION_ERA', 'CONDITION_OCCURRENCE', 'COST', 'DEATH', 'DEVICE_EXPOSURE',
  'DOSE_ERA', 'DRUG_ERA', 'DRUG_EXPOSURE', 'FACT_RELATIONSHIP', 'LOCATION', 'MEASUREMENT', 'METADATA', 'NOTE', 'NOTE_NLP', 'OBSERVATION',
  'OBSERVATION_PERIOD', 'PAYER_PLAN_PERIOD', 'PERSON', 'PROCEDURE_OCCURRENCE', 'PROVIDER', 'SPECIMEN', 'VISIT_DETAIL', 'VISIT_OCCURRENCE',
  'EPISODE', 'EPISODE_EVENT')
ORDER BY c.reltuples DESC
;
