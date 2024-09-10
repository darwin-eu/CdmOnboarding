select
	domain as domain,
  type_concept_id as type_concept_id,
  concept_name as type_concept_name,
  standard_concept as type_standard_concept,
  count_value as count_value,
	first_start_date as first_start_date,
  last_start_date as last_start_date,
	first_end_date as first_end_date,
  last_end_date as last_end_date
from (
	select
		'Obs. Period' as domain,
    period_type_concept_id as type_concept_id,
    count_big(*) as count_value,
		min(observation_period_start_date) as first_start_date,
		max(observation_period_start_date) as last_start_date,
		min(observation_period_end_date) as first_end_date,
		max(observation_period_end_date) as last_end_date
	from @cdmDatabaseSchema.observation_period
  group by period_type_concept_id
  union all
	select
  	'Condition' as domain,
    condition_type_concept_id,
    count_big(*) as count_value,
		min(condition_start_date) as first_start_date,
		max(condition_start_date) as last_start_date,
		min(condition_end_date) as first_end_date,
		max(condition_end_date) as last_end_date
  from @cdmDatabaseSchema.condition_occurrence
  group by condition_type_concept_id
  union all
	select
    'Drug' as domain,
    drug_type_concept_id,
    count_big(*) as count_value,
		min(drug_exposure_start_date) as first_start_date,
		max(drug_exposure_start_date) as last_start_date,
		min(drug_exposure_end_date) as first_end_date,
		max(drug_exposure_end_date) as last_end_date
 	from @cdmDatabaseSchema.drug_exposure
  group by drug_type_concept_id
  union all
	select
  	'Death' as domain,
    death_type_concept_id,
    count_big(*) as count_value,
		min(death_date) as first_start_date,
		max(death_date) as last_start_date,
    NULL,
    NULL
  from @cdmDatabaseSchema.death
  group by death_type_concept_id
  union all
	select
  	'Device' as domain,
    device_type_concept_id,
    count_big(*) as count_value,
		min(device_exposure_start_date) as first_start_date,
		max(device_exposure_start_date) as last_start_date,
		min(device_exposure_end_date) as first_end_date,
		max(device_exposure_end_date) as last_end_date
  from @cdmDatabaseSchema.device_exposure
  group by device_type_concept_id
  union all
	select
  	'Measurement' as domain,
    measurement_type_concept_id,
    count_big(*) as count_value,
		min(measurement_date) as first_start_date,
		max(measurement_date) as last_start_date,
    NULL,
    NULL
  from @cdmDatabaseSchema.measurement
  group by measurement_type_concept_id
  UNION
	select
  	'Observation' as domain,
    observation_type_concept_id,
    count_big(*) as count_value,
		min(observation_date) as first_start_date,
		max(observation_date) as last_start_date,
    NULL,
    NULL
  from @cdmDatabaseSchema.observation
  group by observation_type_concept_id
  union all
	select
  	'Procedure' as domain,
    procedure_type_concept_id,
    count_big(*) as count_value,
		min(procedure_date) as first_start_date,
		max(procedure_date) as last_start_date,
    {@cdmVersion == '5.4'} ? {
		min(procedure_end_date) as first_end_date,
		max(procedure_end_date) as last_end_date
    } : {
    NULL,
    NULL
    }
  from @cdmDatabaseSchema.procedure_occurrence
  group by procedure_type_concept_id
  union all
  select
  	'Specimen' as domain,
    specimen_type_concept_id,
    count_big(*) as count_value,
		min(specimen_date) as first_start_date,
		max(specimen_date) as last_start_date,
    NULL,
    NULL
  from @cdmDatabaseSchema.specimen
  group by specimen_type_concept_id
  union all
  select
  	'Visit' as domain,
    visit_type_concept_id,
    count_big(*) as count_value,
		min(visit_start_date) as first_start_date,
		max(visit_start_date) as last_start_date,
		min(visit_end_date) as first_end_date,
		max(visit_end_date) as last_end_date
  from @cdmDatabaseSchema.visit_occurrence
  group by visit_type_concept_id
  union all
  select
  	'Visit Detail' as domain,
    visit_detail_type_concept_id,
    count_big(*) as count_value,
		min(visit_detail_start_date) as first_start_date,
		max(visit_detail_start_date) as last_start_date,
		min(visit_detail_end_date) as first_end_date,
		max(visit_detail_end_date) as last_end_date
  from @cdmDatabaseSchema.visit_detail
  group by visit_detail_type_concept_id
  union all
	select
  	'Payer Plan Period' as domain,
    NULL,
    count_big(*) as count_value,
		min(payer_plan_period_start_date) as first_start_date,
		max(payer_plan_period_start_date) as last_start_date,
    min(payer_plan_period_end_date) as first_end_date,
    max(payer_plan_period_end_date) as last_end_date
  from @cdmDatabaseSchema.payer_plan_period
  union all
  select
  	'Note' as domain,
    note_type_concept_id,
    count_big(*) as count_value,
		min(note_date) as first_start_date,
		max(note_date) as last_start_date,
    NULL,
    NULL
	from @cdmDatabaseSchema.note
  group by note_type_concept_id
  {@cdmVersion == '5.4'} ? {
  union all
  select
    'Episode' as domain,
    episode_type_concept_id,
    count_big(*) as count_value,
  	min(episode_start_date) as first_start_date,
  	max(episode_start_date) as last_start_date,
    min(episode_end_date) as first_end_date,
    max(episode_end_date) as last_end_date
  from @cdmDatabaseSchema.episode
  group by episode_type_concept_id
  }
) cte
left join @cdmDatabaseSchema.concept 
  on cte.type_concept_id = concept_id
;