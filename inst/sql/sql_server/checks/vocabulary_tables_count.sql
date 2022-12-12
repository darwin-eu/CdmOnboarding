-- count on vocabulary tables check

select 'concept' as tablename, count(*) as count from @vocabDatabaseSchema.concept
UNION ALL
select 'concept_ancestor' as tablename, count(*) as count from @vocabDatabaseSchema.concept_ancestor
UNION ALL
select 'concept_class' as tablename, count(*) as count from @vocabDatabaseSchema.concept_class
UNION ALL
select 'concept_relationship' as tablename, count(*) as count from @vocabDatabaseSchema.concept_relationship
UNION ALL
select 'concept_synonym' as tablename, count(*) as count from @vocabDatabaseSchema.concept_synonym
UNION ALL
select 'domain' as tablename, count(*) as count from @vocabDatabaseSchema.domain
UNION ALL
select 'drug_strength' as tablename, count(*) as count from @vocabDatabaseSchema.drug_strength
UNION ALL
select 'vocabulary' as tablename, count(*) as count from @vocabDatabaseSchema.vocabulary
UNION ALL
select 'relationship' as tablename, count(*) as count from @vocabDatabaseSchema.relationship
