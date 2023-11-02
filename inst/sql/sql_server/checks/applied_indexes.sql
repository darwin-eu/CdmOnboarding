SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = '@vocabDatabaseSchema'
ORDER BY
    tablename,
    indexname;