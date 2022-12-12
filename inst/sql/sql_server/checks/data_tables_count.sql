-- Clinical data table counts

select 'person' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.person
UNION ALL
select 'care_site' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.care_site
UNION ALL
select 'condition_era' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.condition_era
UNION ALL
select 'condition_occurrence' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.condition_occurrence
UNION ALL
select 'drug_exposure' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.drug_exposure
UNION ALL
select 'cost' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.cost
UNION ALL
select 'death' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.death
UNION ALL
select 'device_exposure' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.device_exposure
UNION ALL
select 'dose_era' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.dose_era
UNION ALL
select 'drug_era' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.drug_era
UNION ALL
select 'location' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.location
UNION ALL
select 'measurement' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.measurement
UNION ALL
select 'note' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.note
UNION ALL
select 'note_nlp' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.note_nlp
UNION ALL
select 'observation' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.observation
UNION ALL
select 'observation_period' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.observation_period
UNION ALL
select 'payer_plan_period' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.payer_plan_period
UNION ALL
select 'procedure_occurrence' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.procedure_occurrence
UNION ALL
select 'provider' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.provider
UNION ALL
select 'specimen' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.specimen
UNION ALL
select 'visit_detail' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.visit_detail
UNION ALL
select 'visit_occurrence' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.visit_occurrence
UNION ALL
select 'fact_relationship' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.fact_relationship
UNION ALL
select 'metadata' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.metadata
UNION ALL
select 'cdm_source' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.cdm_source
{@cdmVersion == '5.4'} ? {
UNION ALL
select 'episode' as tablename, count_big(*) as count, count_big(distinct person_id) as "person count" from @cdmDatabaseSchema.episode
UNION ALL
select 'episode_event' as tablename, count_big(*) as count, NULL as "person count" from @cdmDatabaseSchema.episode_event
}
