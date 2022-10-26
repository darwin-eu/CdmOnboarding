select
  stratum_1 as "X_CALENDAR_MONTH",
  count_value as "Y_RECORD_COUNT",
  'Observation Period' as "SERIES_NAME"
from @resultsDatabaseSchema.achilles_results
where analysis_id = 110
;
