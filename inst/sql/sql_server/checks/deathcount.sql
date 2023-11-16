SELECT
  CASE analysis_id
    WHEN 110 THEN 'Observation Period'
    WHEN 502 THEN 'Death'
    ELSE ''
  END                AS domain,
  count_value        AS n_persons
FROM @resultsDatabaseSchema.achilles_results_dist
WHERE analysis_id IN (110, 502)
;
