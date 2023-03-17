-- Preprocessing tables for mapping completeness, mapped and unmapped per domain.
-- Considered unmapped when concept_id is 0 or larger than 2Billion
select
  ISNULL(visit_source_value, '') as source_value,
  visit_concept_id as concept_id,
  case when visit_concept_id = 0 or visit_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #visit
from @cdmDatabaseSchema.visit_occurrence
group by visit_concept_id, visit_source_value
;

select
  ISNULL(condition_source_value, '') as source_value,
  condition_concept_id as concept_id,
  case when condition_concept_id = 0 or condition_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #condition
from @cdmDatabaseSchema.condition_occurrence
group by condition_concept_id, condition_source_value
;

select
  ISNULL(procedure_source_value, '') as source_value,
  procedure_concept_id as concept_id,
  case when procedure_concept_id = 0 or procedure_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #procedure
from @cdmDatabaseSchema.procedure_occurrence
group by procedure_concept_id, procedure_source_value
;

select
  ISNULL(drug_source_value, '') as source_value,
  drug_concept_id as concept_id,
  case when drug_concept_id = 0 or drug_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records,
  {@optimize} ? {0} : {count_big(distinct person_id)} as num_patients
into #drug
from @cdmDatabaseSchema.drug_exposure
group by drug_concept_id, drug_source_value
;

select
  ISNULL(observation_source_value, '') as source_value,
  observation_concept_id as concept_id,
  case when observation_concept_id = 0 or observation_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #observation
from @cdmDatabaseSchema.observation
group by observation_concept_id, observation_source_value
;

select
  ISNULL(measurement_source_value, '') as source_value,
  measurement_concept_id as concept_id,
  case when measurement_concept_id = 0 or measurement_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #measurement
from @cdmDatabaseSchema.measurement
group by measurement_concept_id, measurement_source_value
;

select
  ISNULL(device_source_value, '') as source_value,
  device_concept_id as concept_id,
  case when device_concept_id = 0 or device_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #device
from @cdmDatabaseSchema.device_exposure
group by device_concept_id, device_source_value
;

select
  ISNULL(unit_source_value, '') as source_value,
  unit_concept_id as concept_id,
  case when unit_concept_id = 0 or unit_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #meas_unit
from @cdmDatabaseSchema.measurement
where unit_concept_id IS NOT NULL
group by unit_concept_id, unit_source_value
;

select
  ISNULL(unit_source_value, '') as source_value,
  unit_concept_id as concept_id,
  case when unit_concept_id = 0 or unit_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #obs_unit
from @cdmDatabaseSchema.observation
where unit_concept_id IS NOT NULL
group by unit_concept_id, unit_source_value
;

select
  ISNULL(value_source_value, '') as source_value,
  value_as_concept_id as concept_id,
  case when value_as_concept_id = 0 or value_as_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #meas_value
from @cdmDatabaseSchema.measurement
where value_as_concept_id IS NOT NULL
group by value_as_concept_id, value_source_value
;

select
  '' as source_value,
  value_as_concept_id as concept_id,
  case when value_as_concept_id = 0 or value_as_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #obs_value
from @cdmDatabaseSchema.observation
where value_as_concept_id IS NOT NULL
group by value_as_concept_id
;

select
  ISNULL(specialty_source_value, '') as source_value,
  specialty_concept_id as concept_id,
  case when specialty_concept_id = 0 or specialty_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #specialty
from @cdmDatabaseSchema.provider
where specialty_concept_id IS NOT NULL
group by specialty_concept_id, specialty_source_value
;

select
  ISNULL(specimen_source_value, '') as source_value,
  specimen_concept_id as concept_id,
  case when specimen_concept_id = 0 or specimen_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #specimen
from @cdmDatabaseSchema.specimen
where specimen_concept_id IS NOT NULL
group by specimen_concept_id, specimen_source_value
;

select
  ISNULL(cause_source_value, '') as source_value,
  cause_concept_id as concept_id,
  case when cause_concept_id = 0 or cause_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #death_cause
from @cdmDatabaseSchema.death
where cause_concept_id IS NOT NULL
group by cause_concept_id, cause_source_value
;

select
  ISNULL(condition_status_source_value, '') as source_value,
  condition_status_concept_id as concept_id,
  case when condition_status_concept_id = 0 or condition_status_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #cond_status
from @cdmDatabaseSchema.condition_occurrence
where condition_status_concept_id IS NOT NULL
group by condition_status_concept_id, condition_status_source_value
;

select
  ISNULL(route_source_value, '') as source_value,
  route_concept_id as concept_id,
  case when route_concept_id = 0 or route_concept_id > 2000000000 then 0 else 1 end as is_mapped,
  count_big(*) as num_records
into #drug_route
from @cdmDatabaseSchema.drug_exposure
where route_concept_id IS NOT NULL
group by route_concept_id, route_source_value
;
