SELECT
  CASE analysis_id
    WHEN 203 THEN 'Visit Occurrence'
    WHEN 403 THEN 'Condition Occurrence'
    WHEN 603 THEN 'Procedure Occurrence'
    WHEN 703 THEN 'Drug exposure'
    WHEN 803 THEN 'Observation'
    WHEN 903 THEN 'Drug era'
    WHEN 1003 THEN 'Condition era'
    WHEN 1803 THEN 'Measurement'
    ELSE ''
  END                AS domain,
  count_value        AS n_persons,
  min_value          AS min,
  p10_value          AS p10,
  p25_value          AS p25,
  median_value       AS median,
  p75_value          AS p75,
  p90_value          AS p90,
  max_value          AS max
FROM @resultsDatabaseSchema.achilles_results_dist
WHERE analysis_id IN (203, 403, 603, 703, 803, 903, 1003, 1803)
;
