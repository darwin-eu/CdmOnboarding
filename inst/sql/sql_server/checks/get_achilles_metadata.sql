SELECT
  stratum_2 as achilles_version,
  stratum_3 as achilles_execution_date
FROM @resultsDatabaseSchema.achilles_results
WHERE analysis_id = 0
;
