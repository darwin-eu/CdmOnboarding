  SELECT
    CASE ar.analysis_id
      WHEN 111 THEN 'Observation Period'
      WHEN 220 THEN 'Visit Occurrence'
      WHEN 420 THEN 'Condition Occurrence'
      WHEN 502 THEN 'Death'
      WHEN 620 THEN 'Procedure Occurrence'
      WHEN 720 THEN 'Drug Exposure'
      WHEN 820 THEN 'Observation'
      WHEN 920 THEN 'Drug Era'
      WHEN 1020 THEN 'Condition Era'
      WHEN 1820 THEN 'Measurement'
      WHEN 2120 THEN 'Device Exposure'
      ELSE ''
    END                                                AS series_name,
    ar.stratum_1                                       AS x_Calendar_Month,
    round(1.0 * ar.count_value / denom.count_value, 5) AS y_Record_Count
FROM @resultsDatabaseSchema.achilles_results AS ar
INNER JOIN @resultsDatabaseSchema.achilles_results AS denom
  ON ar.stratum_1 = denom.stratum_1 AND denom.analysis_id = 117
WHERE ar.analysis_id IN (111, 220, 420, 502, 620, 720, 820, 920, 1020, 1820, 2120)
ORDER BY series_Name, CAST(CASE WHEN isNumeric(ar.stratum_1) = 1 THEN ar.stratum_1 ELSE null END AS INT)
;
