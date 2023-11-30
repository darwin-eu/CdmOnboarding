select
    stratum_1 AS n_observation_periods,
    count_value AS n_persons
from @resultsDatabaseSchema.achilles_results
where analysis_id = 113
;