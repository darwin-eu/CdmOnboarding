-- Levels at which drugs are mapped

select concept_class_id as "Class",
       sum(num_records) as "#Records",
       sum(num_patients) as "#Patients",
       count_big(distinct source_value) as "#Source Codes",
       round(sum(num_records)/t.total_records*100,1) as "%Records"
from #drug
cross join (select sum(num_records) as total_records from #drug) t
join @vocabDatabaseSchema.concept on drug.concept_id=concept.concept_id
group by concept_class_id, t.total_records
order by "#Source Codes" DESC
