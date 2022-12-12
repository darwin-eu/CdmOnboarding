-- Estimate of cdm table counts
SELECT
  t.[name] as tablename,
  SUM(p.rows) as count,
  NULL as "person count"
FROM sys.partitions AS p
INNER JOIN sys.tables AS t ON p.[object_id] = t.[object_id]
INNER JOIN sys.schemas AS s ON s.[schema_id] = t.[schema_id]
WHERE s.name = N'@cdmDatabaseSchema'
AND p.index_id IN (0,1)
and upper(t.[name]) in (
  'CARE_SITE', 'CDM_SOURCE', 'COHORT', 'COHORT_ATTRIBUTE', 'CONDITION_ERA', 'CONDITION_OCCURRENCE', 'COST', 'DEATH', 'DEVICE_EXPOSURE',
  'DOSE_ERA', 'DRUG_ERA', 'DRUG_EXPOSURE', 'FACT_RELATIONSHIP', 'LOCATION', 'MEASUREMENT', 'METADATA', 'NOTE', 'NOTE_NLP', 'OBSERVATION',
  'OBSERVATION_PERIOD', 'PAYER_PLAN_PERIOD', 'PERSON', 'PROCEDURE_OCCURRENCE', 'PROVIDER', 'SPECIMEN', 'VISIT_DETAIL', 'VISIT_OCCURRENCE',
  'EPISODE', 'EPISODE_EVENT')
GROUP BY t.[name]
ORDER BY SUM(p.rows) DESC
;
