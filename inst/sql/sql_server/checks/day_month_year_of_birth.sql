with cte1 as (
    select 
        'Year' as variable,
        year_of_birth as count_value
    from @cdmDatabaseSchema.person
    union all
    select 
        'Month' as variable,
        month_of_birth as count_value
    from @cdmDatabaseSchema.person
    union all
    select 
        'Day' as variable,
        day_of_birth as count_value
    from @cdmDatabaseSchema.person
), overallStats as (
    select 
        variable,
        count_big(*) as total,
        min(count_value) as min_value,
        max(count_value) as max_value,
        sum(CASE WHEN count_value IS NULL THEN 1 ELSE 0 END) as missing_value
    from cte1
    group by variable
), statsView as (
    select
        variable,
        count_value,
        count_big(*) as total,
        row_number() over (partition by variable order by count_value) as rn
    from cte1
    group by variable, count_value
), priorStats as (
  select
    s.variable,
    s.count_value,
    sum(p.total) as accumulated
  from statsView s
  join statsView p on s.variable = p.variable and p.rn <= s.rn
  group by s.variable, s.count_value, s.total, s.rn
)
select
    o.variable,
    100.0 * o.missing_value / o.total as p_missing,
    o.min_value,
	o.max_value,
    min(case when p.accumulated >= .10 * o.total then p.count_value else o.max_value end) as p10_value,
    min(case when p.accumulated >= .25 * o.total then p.count_value else o.max_value end) as p25_value,
    min(case when p.accumulated >= .50 * o.total then p.count_value else o.max_value end) as median_value,
    min(case when p.accumulated >= .75 * o.total then p.count_value else o.max_value end) as p75_value,
    min(case when p.accumulated >= .90 * o.total then p.count_value else o.max_value end) as p90_value
from priorStats p
join overallStats o on p.variable = o.variable
GROUP BY o.variable, o.min_value, o.max_value, o.missing_value, o.total
;