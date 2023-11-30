-- Count pairs of overlapping observation periods per person.
-- Observation periods overlap if, for the same person, the start date of one observation period is 
-- before the end date of another observation period AND the end date is after the start date.
-- Both periods are captured as overlapping, so the count has to be divided by 2 to get number of 
-- overlapping pairs of observation periods.
SELECT 
  a.person_id,
  COUNT(*)/2 AS n_overlapping_pairs
FROM @cdmDatabaseSchema.observation_period AS a
JOIN @cdmDatabaseSchema.observation_period AS b ON
      a.person_id = b.person_id 
  AND a.observation_period_start_date <= b.observation_period_end_date 
  AND a.observation_period_end_date >= b.observation_period_start_date
  AND a.observation_period_id <> b.observation_period_id
GROUP BY a.person_id
;
