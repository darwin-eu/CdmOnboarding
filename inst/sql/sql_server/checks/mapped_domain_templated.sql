-- top 25 mapped

select top 25
  ROW_NUMBER() OVER(ORDER BY num_records desc) as "#",
  cdm_table.concept_id as "Concept id",
  concept_name as "Concept Name",
  floor((num_records+99)/100)*100 as "#Records",
  round(num_records/t.total_records*100,1) as "%Records"
from #@cdmDomain as cdm_table
cross join (select sum(num_records) as total_records from #@cdmDomain) t
left join @vocabDatabaseSchema.concept as concept on cdm_table.concept_id = concept.concept_id
where is_mapped = 1 and num_records > @smallCellCount
order by num_records desc
;
