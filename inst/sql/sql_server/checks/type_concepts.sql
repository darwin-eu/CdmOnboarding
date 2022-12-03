select
  domain,
  type_concept_id as type_concept_id,
  concept_name + ' (' + cast(type_concept_id as varchar) + ')' as type_concept_name,
  floor((record_count+99)/100)*100 as "count"
from (
  select 'Observation Period' as domain, period_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.observation_period
    group by type_concept_id
  UNION ALL
  select 'Visit' as domain, visit_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.visit_occurrence
	  group by type_concept_id
  UNION ALL
  select 'Visit Detail' as domain, visit_detail_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.visit_detail
	  group by type_concept_id
  UNION ALL
  select 'Death' as domain, death_type_concept_id AS type_concept_id, count_big(*) as record_count
	from @cdmDatabaseSchema.death
	  group by type_concept_id
  UNION ALL
  select 'Condition' as domain, condition_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.condition_occurrence
	  group by type_concept_id
  UNION ALL
  select 'Drug' as domain, drug_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.drug_exposure
	  group by type_concept_id
  UNION ALL
  select 'Procedure' as domain, procedure_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.procedure_occurrence
	  group by type_concept_id
  UNION ALL
  select 'Measurement' as domain, measurement_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.measurement
	  group by type_concept_id
  UNION ALL
  select 'Observation' as domain, observation_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.observation
	  group by type_concept_id
  UNION ALL
  select 'Device' as domain, device_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.device_exposure
	  group by type_concept_id
  UNION ALL
  select 'Note' as domain, note_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.note
	  group by type_concept_id
  UNION ALL
  select 'Specimen' as domain, specimen_type_concept_id AS type_concept_id, count_big(*) as record_count
  from @cdmDatabaseSchema.specimen
	  group by type_concept_id
) cte
join @vocabDatabaseSchema.concept on type_concept_id = concept_id
;
