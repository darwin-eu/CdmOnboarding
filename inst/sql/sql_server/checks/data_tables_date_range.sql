select
  tablename as "Table",
  YEAR(min(start_date)) *100 + MONTH(min(start_date)) as "First event start month",
  YEAR(max(start_date)) *100 + MONTH(max(start_date)) as "Last event start month"
from (
  select 'condition_occurrence' as tablename, condition_start_date as start_date
  from @cdmDatabaseSchema.condition_occurrence
  UNION
  select 'drug_exposure' as tablename, drug_exposure_start_date as start_date
  from @cdmDatabaseSchema.drug_exposure
  UNION
  select 'death' as tablename, death_date as start_date
  from @cdmDatabaseSchema.death
  UNION
  select 'device_exposure' as tablename, device_exposure_start_date as start_date
  from @cdmDatabaseSchema.device_exposure
  UNION
  select 'measurement' as tablename, measurement_date as start_date
  from @cdmDatabaseSchema.measurement
  UNION
  select 'observation' as tablename, observation_date as start_date
  from @cdmDatabaseSchema.observation
  UNION
  select 'procedure_occurrence' as tablename, procedure_date as start_date
  from @cdmDatabaseSchema.procedure_occurrence
  UNION
  select 'specimen' as tablename, specimen_date as start_date
  from @cdmDatabaseSchema.specimen
  UNION
  select 'visit_detail' as tablename, visit_detail_start_date as start_date
  from @cdmDatabaseSchema.visit_detail
  UNION
  select 'visit_occurrence' as tablename, visit_start_date as start_date
  from @cdmDatabaseSchema.visit_occurrence
  UNION
  select 'payer_plan_period' as tablename, payer_plan_period_start_date as start_date
  from @cdmDatabaseSchema.payer_plan_period
  UNION
  select 'note' as tablename, note_date as start_date
  from @cdmDatabaseSchema.note
  {@cdmVersion in ('5.4', '5.4.0')} ? {
  UNION
  select 'episode' as tablename, episode_start_date as start_date
  from @cdmDatabaseSchema.episode
  }
) cte
group by tablename
;
