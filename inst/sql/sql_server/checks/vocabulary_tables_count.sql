-- count on vocabulary tables check

select 'concept' as tablename, count(*) as count from @cdmDatabaseSchema.concept
UNION ALL
select 'concept_ancestor' as tablename, count(*) as count from @cdmDatabaseSchema.concept_ancestor
UNION ALL
select 'concept_class' as tablename, count(*) as count from @cdmDatabaseSchema.concept_class
UNION ALL
select 'concept_relationship' as tablename, count(*) as count from @cdmDatabaseSchema.concept_relationship
UNION ALL
select 'concept_synonym' as tablename, count(*) as count from @cdmDatabaseSchema.concept_synonym
UNION ALL
select 'domain' as tablename, count(*) as count from @cdmDatabaseSchema.domain
UNION ALL
select 'drug_strength' as tablename, count(*) as count from @cdmDatabaseSchema.drug_strength
UNION ALL
select 'vocabulary' as tablename, count(*) as count from @cdmDatabaseSchema.vocabulary
UNION ALL
select 'relationship' as tablename, count(*) as count from @cdmDatabaseSchema.relationship
