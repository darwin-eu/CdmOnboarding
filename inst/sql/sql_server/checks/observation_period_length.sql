select
  round(avg_value,1)   AS "Average",
  round(stdev_value,1) AS "Std Dev",
  min_value            AS "Min",
  p10_value            AS "P10",
  p25_value            AS "P25",
  median_value         AS "MEDIAN",
  p75_value            AS "P75",
  p90_value            AS "P90",
  max_value            AS "Max"
from @resultsDatabaseSchema.achilles_results_dist
where analysis_id = 105;
