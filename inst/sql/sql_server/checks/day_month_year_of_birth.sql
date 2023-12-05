-- TODO: implement with percent_rank or ntile, as percentile_disc is not cross-db compatible
SELECT
    'year_of_birth' as variable,
    avg(year_of_birth) as average,
    STDEV(year_of_birth) as std_dev,
    min(year_of_birth) as minimum,
    percentile_disc(0.1) WITHIN GROUP (ORDER BY year_of_birth) as p10,
    percentile_disc(0.25) WITHIN GROUP (ORDER BY year_of_birth) as p25,
    percentile_disc(0.5) WITHIN GROUP (ORDER BY year_of_birth) as median,
    percentile_disc(0.75) WITHIN GROUP (ORDER BY year_of_birth) as p75,
    percentile_disc(0.9) WITHIN GROUP (ORDER BY year_of_birth) as p90,
    max(year_of_birth) as maximum,
    sum(case when year_of_birth is null then 1 else 0 end) as missing
FROM 
    @cdmDatabaseSchema.person

UNION ALL

SELECT
    'month_of_birth' as variable,
    round(avg(month_of_birth), 1) as average,
    round(STDEV(month_of_birth), 1) as std_dev,
    min(month_of_birth) as minimum,
    percentile_disc(0.1) WITHIN GROUP (ORDER BY month_of_birth) as p10,
    percentile_disc(0.25) WITHIN GROUP (ORDER BY month_of_birth) as p25,
    percentile_disc(0.5) WITHIN GROUP (ORDER BY month_of_birth) as median,
    percentile_disc(0.75) WITHIN GROUP (ORDER BY month_of_birth) as p75,
    percentile_disc(0.9) WITHIN GROUP (ORDER BY month_of_birth) as p90,
    max(month_of_birth) as maximum,
    sum(case when month_of_birth is null then 1 else 0 end) as missing
FROM 
    @cdmDatabaseSchema.person

UNION ALL

SELECT
    'day_of_birth' as variable,
    round(avg(day_of_birth), 1) as average,
    round(STDEV(day_of_birth), 1) as std_dev,
    min(day_of_birth) as minimum,
    percentile_disc(0.1) WITHIN GROUP (ORDER BY day_of_birth) as p10,
    percentile_disc(0.25) WITHIN GROUP (ORDER BY day_of_birth) as p25,
    percentile_disc(0.5) WITHIN GROUP (ORDER BY day_of_birth) as median,
    percentile_disc(0.75) WITHIN GROUP (ORDER BY day_of_birth) as p75,
    percentile_disc(0.9) WITHIN GROUP (ORDER BY day_of_birth) as p90,
    max(day_of_birth) as maximum,
    sum(case when day_of_birth is null then 1 else 0 end) as missing
FROM 
    @cdmDatabaseSchema.person
