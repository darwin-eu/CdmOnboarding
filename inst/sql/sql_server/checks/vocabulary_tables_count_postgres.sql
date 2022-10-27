-- Estimate of cdm table counts
SELECT
    c.relname AS tablename,
    c.reltuples::bigint as count
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r'
  and nspname = '@vocabDatabaseSchema'
  and lower(relname) in (
  'concept', 'concept_ancestor', 'concept_class', 'concept_relationship',
  'concept_synonym', 'domain', 'drug_strength', 'vocabulary', 'relationship')
ORDER BY c.reltuples DESC
;
