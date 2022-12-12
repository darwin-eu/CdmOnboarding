-- top 25 mapped

select top 25
  ROW_NUMBER() OVER(ORDER BY num_records desc) as "#",
  CAST(cte.concept_id AS varchar) as "Concept id",
  concept.concept_name as "Concept Name",
  floor((num_records+99)/100)*100 as "#Records",
  round(num_records/t.total_records*100,1) as "%Records"
  -- ,num_source_codes as "#Source Codes"
from (
  select
    concept_id,
    sum(num_records) as num_records,
    count_big(distinct source_value) as num_source_codes
  from #@cdmDomain
  where is_mapped = 1
  group by concept_id
) as cte
cross join (select sum(num_records) as total_records from #@cdmDomain) as t
left join @vocabDatabaseSchema.concept as concept on cte.concept_id = concept.concept_id
where num_records > @smallCellCount
order by num_records desc
;
