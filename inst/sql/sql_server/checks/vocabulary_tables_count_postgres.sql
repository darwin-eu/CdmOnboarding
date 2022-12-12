-- Estimate of vocabulary table counts
SELECT
    c.relname AS tablename,
    c.reltuples::bigint as count
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r'
  and nspname = '@vocabDatabaseSchema'
  and upper(relname) in (
  'CONCEPT', 'CONCEPT_ANCESTOR', 'CONCEPT_CLASS', 'CONCEPT_RELATIONSHIP',
  'CONCEPT_SYNONYM', 'DOMAIN', 'DRUG_STRENGTH', 'VOCABULARY', 'RELATIONSHIP')
ORDER BY c.reltuples DESC
;
