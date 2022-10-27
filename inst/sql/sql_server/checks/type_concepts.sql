select
  domain,
  type_concept_id as type_concept_id,
  concept_name + '(' + cast(type_concept_id as varchar) + ')'  as type_concept_name,
  floor((count_big(*)+99)/100)*100 AS "count"
from (
  select 'Observation Period' as domain, period_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.observation_period
  UNION ALL
  select 'Visit' as domain, visit_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.visit_occurrence
  UNION ALL
  select 'Visit Detail' as domain, visit_detail_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.visit_detail
  UNION ALL
  select 'Death' as domain, death_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.death
  UNION ALL
  select 'Condition' as domain, condition_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.condition_occurrence
  UNION ALL
  select 'Drug' as domain, drug_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.drug_exposure
  UNION ALL
  select 'Procedure' as domain, procedure_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.procedure_occurrence
  UNION ALL
  select 'Measurement' as domain, measurement_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.measurement
  UNION ALL
  select 'Observation' as domain, observation_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.observation
  UNION ALL
  select 'Device' as domain, device_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.device_exposure
  UNION ALL
  select 'Note' as domain, note_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.note
  UNION ALL
  select 'Specimen' as domain, specimen_type_concept_id AS type_concept_id
  from @cdmDatabaseSchema.specimen
) cte
left join @cdmDatabaseSchema.concept on type_concept_id = concept_id
group by domain, type_concept_id, concept_name
;
