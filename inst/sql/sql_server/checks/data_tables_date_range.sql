select
  CASE analysis_id
    WHEN 111 THEN 'Observation Period'
    WHEN 502 THEN 'Death'
    WHEN 1411 THEN 'Payer Plan Period'
    WHEN 2102 THEN 'Device exposure'
    WHEN 220 THEN 'Visit Occurrence'
    WHEN 420 THEN 'Condition Occurrence'
    WHEN 620 THEN 'Procedure Occurrence'
    WHEN 720 THEN 'Drug exposure'
    WHEN 820 THEN 'Observation'
    WHEN 920 THEN 'Drug era'
    WHEN 1020 THEN 'Condition era'
    WHEN 1320 THEN 'Visit detail'
    WHEN 1820 THEN 'Measurement'
    ELSE ''
  END AS "Table",
  left(min_start_month, 4) + '-' + right(min_start_month, 2) as "First start month",
  left(max_start_month, 4) + '-' + right(max_start_month, 2) as "Last start month"
from (
	select
	  analysis_id,
	  min(stratum_1) as min_start_month,
	  max(stratum_1) as max_start_month
	from @resultsDatabaseSchema.achilles_results
	where analysis_id IN (111, 502, 1411, 220, 420, 620, 720, 820, 920, 1020, 1320, 1820)
	group by analysis_id

	UNION ALL

	-- No analysis 2120 for device expsoure. 2102 uses stratum_1 to stratify by concept_id
	select
	  analysis_id,
	  min(stratum_2),
	  max(stratum_2)
	from @resultsDatabaseSchema.achilles_results
	where analysis_id IN (2102)
	group by analysis_id

	-- Missing domains (no achilles analysis defined): Note, Specimen, Episode
) cte
;
