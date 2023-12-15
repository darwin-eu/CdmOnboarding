SELECT
    tablename as tablename,
    indexname as indexname
FROM
    pg_indexes
WHERE
    schemaname = '@cdmDatabaseSchema'
ORDER BY
    tablename,
    indexname
;