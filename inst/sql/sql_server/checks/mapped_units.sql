-- top 25 mapped units

SELECT *
FROM (
	select ROW_NUMBER() OVER(ORDER BY count_big(*) DESC) AS ROW_NUM,
	     source_table as "Table",
       Cr.concept_name as "Concept Name",
       floor((count_big(*)+99)/100)*100 as "#Records"
  from (
    select 'observation' as source_table, unit_concept_id
    from @cdmDatabaseSchema.observation
    union all
    select 'measurement' as source_table, unit_concept_id
    from @cdmDatabaseSchema.measurement
  ) C
  JOIN @vocabDatabaseSchema.CONCEPT CR
    ON C.unit_concept_id = CR.CONCEPT_ID
  where c.unit_concept_id != 0
  group by C.source_table, CR.concept_name
  having count_big(*)>@smallCellCount
) z
WHERE z.ROW_NUM <= 25
ORDER BY z.ROW_NUM
