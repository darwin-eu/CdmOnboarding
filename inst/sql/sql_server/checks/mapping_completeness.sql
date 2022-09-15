create temporary table @scratchDatabaseSchema.condition as
  select
    'Condition' as domain,
    condition_source_value,
    case when condition_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
  from @cdmDatabaseSchema.condition_occurrence
  group by condition_source_value, case when condition_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.procedure as
  select
    'Procedure' as domain,
    procedure_source_value,
    case when procedure_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
  from @cdmDatabaseSchema.procedure_occurrence
  group by procedure_source_value, case when procedure_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.device as
  select
    'Device' as domain,
    device_source_value,
    case when device_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
  from @cdmDatabaseSchema.device_exposure
  group by device_source_value, case when device_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.drug as
  select
    'Drug' as domain,
    drug_source_value,
    case when drug_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
  from @cdmDatabaseSchema.drug_exposure
  group by drug_source_value, case when drug_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.observation as
  select
    'Observation'  as domain,
    observation_source_value,
    case when observation_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
  from @cdmDatabaseSchema.observation
  group by observation_source_value, case when observation_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.measurement as
  select
    'Observation'  as domain,
    measurement_source_value,
    case when measurement_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
  from @cdmDatabaseSchema.measurement
  group by measurement_source_value, case when measurement_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.visit as
  select
    'Visit'  as domain,
    case when visit_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
  from @cdmDatabaseSchema.visit_occurrence
  group by visit_source_value, case when visit_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.meas_unit as
  select
    'Measurement Unit'as domain,
    case when unit_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
   from @cdmDatabaseSchema.measurement
   where unit_concept_id IS NOT NULL
   group by unit_source_value, case when unit_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.obs_unit as
  select
    'Observation Unit'  as domain,
    case when unit_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
   from @cdmDatabaseSchema.observation
   where unit_concept_id IS NOT NULL
   group by unit_source_value, case when unit_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.meas_value as
  select
    'Measurement value'  as domain,  case when value_as_concept_id > 0 then 1 else 0 end as is_mapped, count_big(*) as num_records
   from @cdmDatabaseSchema.measurement
   where value_as_concept_id IS NOT NULL
   group by value_source_value, case when value_as_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.obs_value as
  select
    'Observation value'  as domain,
    case when value_as_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
   from @cdmDatabaseSchema.observation
   where value_as_concept_id IS NOT NULL
   group by case when value_as_concept_id > 0 then 1 else 0 end
;

create temporary table @scratchDatabaseSchema.specialty as
  select
    'Provider Specialty'  as domain,
    case when specialty_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
   from @cdmDatabaseSchema.provider
   where specialty_concept_id IS NOT NULL
   group by specialty_source_value, case when specialty_concept_id > 0 then 1 else 0 end
;

create temporary table @scratchDatabaseSchema.specimen as
  select
    'Specimen'  as domain,
    case when specimen_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
   from @cdmDatabaseSchema.specimen
   where specimen_concept_id IS NOT NULL
   group by specimen_source_value, case when specimen_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.death_cause as
  select
    'Death cause'  as domain,
    case when cause_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
   from @cdmDatabaseSchema.death
   where cause_concept_id IS NOT NULL
   group by cause_source_value, case when cause_concept_id > 0 then 1 else 0 end
;


create temporary table @scratchDatabaseSchema.cond_status as
  select
    'Condition status' as domain,
    case when condition_status_concept_id > 0 then 1 else 0 end as is_mapped,
    count_big(*) as num_records
   from @cdmDatabaseSchema.condition_occurrence
   where condition_status_concept_id IS NOT NULL
   group by condition_status_source_value, case when condition_status_concept_id > 0 then 1 else 0 end
;

select  domain as "Domain",
        count_big(*) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(*) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(case when is_mapped = 1 then num_records else 0 end) as "#Records Mapped",
        100.0*sum(case when is_mapped = 1 then num_records else 0 end)/sum(num_records) as "%Records Mapped"
from (
  select * from condition
  union
  select * from procedure
  union
  select * from drug
  union
  select * from device
  union
  select * from observation
  union
  select * from measurement
  union
  select * from specimen
  union
  select * from visit
  union
  select * from meas_unit
  union
  select * from obs_unit
  union
  select * from meas_value
  union
  select * from obs_value
  union
  select * from specialty
  union
  select * from cond_status
  union
  select * from death_cause
) T
group by domain
;

