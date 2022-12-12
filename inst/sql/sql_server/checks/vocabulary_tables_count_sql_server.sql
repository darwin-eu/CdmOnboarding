-- Estimate of vocabulary table counts
SELECT
  t.[name] as tablename,
  SUM(p.rows) as count
FROM sys.partitions AS p
INNER JOIN sys.tables AS t ON p.[object_id] = t.[object_id]
INNER JOIN sys.schemas AS s ON s.[schema_id] = t.[schema_id]
WHERE s.name = N'@vocabDatabaseSchema'
AND p.index_id IN (0,1)
and upper(t.[name]) in (
  'CONCEPT', 'CONCEPT_ANCESTOR', 'CONCEPT_CLASS', 'CONCEPT_RELATIONSHIP',
  'CONCEPT_SYNONYM', 'DOMAIN', 'DRUG_STRENGTH', 'VOCABULARY', 'RELATIONSHIP')
GROUP BY t.[name]
ORDER BY SUM(p.rows) DESC
;
