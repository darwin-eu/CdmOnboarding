-- top 25 unmapped

select top 25
	ROW_NUMBER() OVER(ORDER BY num_records desc) as row_num,
	source_value as source_value,
	floor((num_records+99)/100)*100 as n_records,
	100.0 * num_records/t.total_records as p_records
from #@cdmDomain as cte
cross join (select sum(num_records) as total_records from #@cdmDomain) t
where is_mapped = 0 and num_records > @smallCellCount
order by num_records desc
;
