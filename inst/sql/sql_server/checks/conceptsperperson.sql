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
  END                AS "Domain",
  count_value        AS "N_persons",
  min_value          AS "Min",
  p10_value          AS "P10",
  p25_value          AS "P25",
  median_value       AS "MEDIAN",
  p75_value          AS "P75",
  p90_value          AS "P90",
  max_value          AS "Max"
FROM @resultsDatabaseSchema.achilles_results_dist
WHERE analysis_id IN (203, 403, 603, 703, 803, 903, 1003, 1803)
;
