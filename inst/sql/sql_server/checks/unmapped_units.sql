-- Top 25 unmapped units

SELECT *
FROM (
	select ROW_NUMBER() OVER(ORDER BY count_big(*) DESC) AS ROW_NUM,
	     source_table as "Table",
       unit_source_value as "Source Value",
       floor((count_big(*)+99)/100)*100 as "#Records"
  from (
    select 'observation' as source_table, unit_source_value, unit_concept_id
    from @cdmDatabaseSchema.observation
    union all
    select 'measurement' as source_table, unit_source_value, unit_concept_id
    from @cdmDatabaseSchema.measurement
  ) C
  where unit_concept_id = 0
  group by source_table, unit_source_value
  having count_big(*)>@smallCellCount
) z
WHERE z.ROW_NUM <= 25
ORDER BY z.ROW_NUM
