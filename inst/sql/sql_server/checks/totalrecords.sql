  SELECT
    CASE analysis_id
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
    END                AS series_name,
    stratum_1          AS x_Calendar_Month,
    count_value        AS y_Record_Count
FROM results_synthea.achilles_results
WHERE analysis_id IN (111, 220, 420, 502, 620, 720, 820, 920, 1020, 1820, 2120)
ORDER BY series_Name, CAST(CASE WHEN isNumeric(stratum_1) = 1 THEN stratum_1 ELSE null END AS INT)
;
