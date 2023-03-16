select
  stratum_1 as x_calendar_month,
  count_value as y_record_count,
  'Observation Period' as series_name
from @resultsDatabaseSchema.achilles_results
where analysis_id = 110
;
