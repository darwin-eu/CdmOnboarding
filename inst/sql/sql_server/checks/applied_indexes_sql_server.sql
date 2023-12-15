select
    tables.name as tablename,
    indexes.name as indexname
from sys.indexes
    join sys.index_columns ic ON indexes.object_id = ic.object_id and indexes.index_id = ic.index_id
    join sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id
    join sys.tables on indexes.object_id = tables.object_id
    join sys.schemas on tables.schema_id = schemas.schema_id
where
    schemas.name = '@cdmDatabaseSchema'
;