-- top 25 mapped

select top 25
  ROW_NUMBER() OVER(ORDER BY sum(num_records) desc) as "#",
  CAST(cte.concept_id AS varchar) as "Concept id",
  concept_name as "Concept Name",
  floor((sum(num_records)+99)/100)*100 as "#Records",
  round(sum(num_records)/t.total_records*100,1) as "%Records",
  count_big(distinct source_value) as "#Source Codes"
from #@cdmDomain as cte
cross join (select sum(num_records) as total_records from #@cdmDomain) as t
left join @vocabDatabaseSchema.concept as concept on cte.concept_id = concept.concept_id
where is_mapped = 1 and num_records > @smallCellCount
group by cte.concept_id
order by sum(num_records) desc
;
