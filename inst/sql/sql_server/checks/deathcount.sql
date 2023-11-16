SELECT
  CASE analysis_id
    WHEN 420 THEN 'Condition Occurrence'
    WHEN 720 THEN 'Drug Exposure'
    ELSE ''
  END                AS domain,
  count_value        AS n_persons
FROM @resultsDatabaseSchema.achilles_results_dist
WHERE analysis_id IN (420, 720)
;
