select
  round(avg_value,1)   AS average,
  round(stdev_value,1) AS std_dev,
  min_value            AS min,
  p10_value            AS p10,
  p25_value            AS p25,
  median_value         AS median,
  p75_value            AS p75,
  p90_value            AS p90,
  max_value            AS max
from @resultsDatabaseSchema.achilles_results_dist
where analysis_id = 105;
