-- top 25 unmapped

select top 25
	ROW_NUMBER() OVER(ORDER BY num_records desc) as "#",
	source_value as "Source Value",
	floor((num_records+99)/100)*100 as "#Records",
	round(num_records/t.total_records*100,1) as "%Records"
from #@cdmDomain
cross join (select sum(num_records) as total_records from #@cdmDomain) t
where is_mapped = 0 and num_records > @smallCellCount
order by num_records desc
;
