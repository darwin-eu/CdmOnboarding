-- Levels at which drugs are mapped

select concept_class_id as class,
       sum(num_records) as n_records,
       sum(num_patients) as n_patients,
       count_big(distinct source_value) as n_source_codes,
       100.0 * sum(num_records)/t.total_records as p_records
from #drug as cte
cross join (select sum(num_records) as total_records from #drug) t
join @vocabDatabaseSchema.concept on cte.concept_id=concept.concept_id
group by concept_class_id, t.total_records
order by n_records DESC
;
