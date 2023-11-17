SELECT
    extract(isodow from condition_start_date) as day_of_week,
    COUNT(*)
FROM cdm.condition_occurrence 
group by 1
