select
    CASE analysis_id
        WHEN 213 THEN 'Visit'
        WHEN 1313 THEN 'Visit Detail'
    END as domain,
    concept_id,
    concept_name,
    count_value,
    avg_value,
    stdev_value,
    min_value,
    p10_value,
    p25_value,
    median_value,
    p75_value,
    p90_value,
    max_value
from @resultsDatabaseSchema.achilles_results_dist
join @cdmDatabaseSchema.concept on stratum_1 = cast(concept_id as VARCHAR)
where analysis_id IN (213, 1313)
;