select
	table_name as "Table",
	left(cast(first_start_date as varchar), 7) as "First start month",
  left(cast(last_start_date as varchar), 7) as "Last start month"
from (
	select
		'Observation Period' as table_name,
		min(observation_period_start_date) as first_start_date,
		max(observation_period_start_date) as last_start_date
	from @cdmDatabaseSchema.observation_period
  UNION ALL
	select
  	'Condition Occurrence' as table_name,
		min(condition_start_date) as first_start_date,
		max(condition_start_date) as last_start_date
  	from @cdmDatabaseSchema.condition_occurrence
  UNION ALL
	select
    'Drug Exposure' as table_name,
		min(drug_exposure_start_date) as first_start_date,
		max(drug_exposure_start_date) as last_start_date
  	from @cdmDatabaseSchema.drug_exposure
  UNION ALL
	select
  	'Death' as table_name,
		min(death_date) as first_start_date,
		max(death_date) as last_start_date
  	from @cdmDatabaseSchema.death
  UNION ALL
	select
  	'Device Exposure' as table_name,
		min(device_exposure_start_date) as first_start_date,
		max(device_exposure_start_date) as last_start_date
  from @cdmDatabaseSchema.device_exposure
  UNION ALL
	select
  	'Measurement' as table_name,
		min(measurement_date) as first_start_date,
		max(measurement_date) as last_start_date
  from @cdmDatabaseSchema.measurement
  UNION
	select
  	'Observation' as table_name,
		min(observation_date) as first_start_date,
		max(observation_date) as last_start_date
  from @cdmDatabaseSchema.observation
  UNION ALL
	select
  	'Procedure Occurrence' as table_name,
		min(procedure_date) as first_start_date,
		max(procedure_date) as last_start_date
  from @cdmDatabaseSchema.procedure_occurrence
  UNION ALL
  select
  	'Specimen' as table_name,
		min(specimen_date) as first_start_date,
		max(specimen_date) as last_start_date
  from @cdmDatabaseSchema.specimen
  UNION ALL
  select
  	'Visit Occurrence' as table_name,
		min(visit_start_date) as first_start_date,
		max(visit_start_date) as last_start_date
  from @cdmDatabaseSchema.visit_occurrence
  UNION ALL
  select
  	'Visit Detail' as table_name,
		min(visit_detail_start_date) as first_start_date,
		max(visit_detail_start_date) as last_start_date
  from @cdmDatabaseSchema.visit_detail
  UNION ALL
	select
  	'Payer Plan Period' as table_name,
		min(payer_plan_period_start_date) as first_start_date,
		max(payer_plan_period_start_date) as last_start_date
  from @cdmDatabaseSchema.payer_plan_period
  UNION ALL
  select
  	'Note' as table_name,
		min(note_date) as first_start_date,
		max(note_date) as last_start_date
	from @cdmDatabaseSchema.note
	{@cdmVersion == '5.4'} ? {
  UNION ALL
  select
    'Episode' as table_name,
  	min(episode_start_date) as first_start_date,
  	max(episode_start_date) as last_start_date
  from @cdmDatabaseSchema.episode
	}
) cte
;
