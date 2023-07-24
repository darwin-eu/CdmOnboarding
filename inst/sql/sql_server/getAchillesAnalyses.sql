select distinct analysis_id
from @results_database_schema.achilles_results
where analysis_id < 2000000

UNION

select distinct analysis_id
from @results_database_schema.achilles_results_dist
where analysis_id < 2000000