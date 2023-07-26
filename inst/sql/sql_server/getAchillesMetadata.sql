select
    stratum_1 as achilles_source_name,
    stratum_2 as achilles_version,
    stratum_3 as achilles_execution_date,
    CAST(count_value/1000 as INT) as person_count_thousands
from @results_database_schema.achilles_results
where analysis_id = 0
;