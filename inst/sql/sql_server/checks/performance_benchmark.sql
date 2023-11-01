-- Query benchmark check
-- Note: the second join (with c2) is wrong, first condition should be on c2.concept_id. 
--       However, we will not change the query. The actual result is not used, just the timing.
--       Changing the query potentially makes the timing results incomparable to results from previous version.

SELECT 
  COUNT(*) AS `count`
FROM @vocabDatabaseSchema.concept AS c1
JOIN @vocabDatabaseSchema.concept_relationship AS cr
  ON concept_id = concept_id_1
  AND cr.invalid_reason IS NULL
  AND cr.relationship_id = 'Maps to'
JOIN @vocabDatabaseSchema.concept AS c2
  ON cr.concept_id_2 = c1.concept_id
  AND c1.invalid_reason IS NULL
;
