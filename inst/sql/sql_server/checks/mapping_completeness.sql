select  'Condition' as domain,
        count_big(distinct source_value) as n_codes_source,
        sum(is_mapped) as n_codes_mapped,
        100.0*sum(is_mapped) / count_big(distinct source_value) as p_codes_mapped,
        sum(num_records) as n_records_source,
        sum(is_mapped * num_records) as n_records_mapped,
        100.0*sum(is_mapped * num_records)/sum(num_records) as p_records_mapped
from #condition
union all
select  'Procedure',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #procedure
union all
select  'Drug',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #drug
union all
select  'Device',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #device
union all
select  'Observation',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #observation
union all
select  'Measurement',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #measurement
union all
select  'Specimen',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #specimen
union all
select  'Visit',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #visit
union all
select  'Measurement Unit',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #meas_unit
union all
select  'Observation Unit',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #obs_unit
union all
select  'Measurement value',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #meas_value
union all
select  'Observation value',
        cast(NULL as BIGINT),
        cast(NULL as BIGINT),
        cast(NULL as FLOAT),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #obs_value
union all
select  'Provider Specialty' ,
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #specialty
union all
select  'Condition status',
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #cond_status
union all
select  'Death cause' ,
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #death_cause
union all
select  'Drug Route' ,
        count_big(distinct source_value),
        sum(is_mapped),
        100.0*sum(is_mapped) / count_big(distinct source_value),
        sum(num_records),
        sum(is_mapped * num_records),
        100.0*sum(is_mapped * num_records)/sum(num_records)
from #drug_route
;
