select
  avg_value,
  stdev_value,
  min_value,
  p10_value,
  p25_value,
  median_value,
  p75_value,
  p90_value,
  max_value
from @resultsDatabaseSchema.achilles_results_dist
where analysis_id = 105;
