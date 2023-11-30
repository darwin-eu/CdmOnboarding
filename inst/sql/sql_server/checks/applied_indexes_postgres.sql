SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = '@cdmDatabaseSchema'
ORDER BY
    tablename,
    indexname;