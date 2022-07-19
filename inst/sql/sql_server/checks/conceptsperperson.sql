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
  END                AS category,
  min_Value          AS min_Value,
  p10_Value          AS p10_Value,
  p25_Value          AS p25_Value,
  median_Value       AS median_Value,
  p75_Value          AS p75_Value,
  p90_Value          AS p90_Value,
  max_Value          AS max_Value
FROM @resultsDatabaseSchema.achilles_results_dist
WHERE analysis_id IN (203, 403, 603, 703, 803, 903, 1003, 1803)
;
