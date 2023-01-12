select  'Condition' as "Domain",
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #condition
union all
select  'Procedure' as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #procedure
union all
select  'Drug' as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #drug
union all
select  'Device' as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #device
union all
select  'Observation'  as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #observation
union all
select  'Measurement'  as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #measurement
union all
select  'Specimen' as "Domain",
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #specimen
union all
select  'Visit' as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #visit
union all
select  'Measurement Unit'as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #meas_unit
union all
select  'Observation Unit'as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #obs_unit
union all
select  'Measurement value'  as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #meas_value
union all
select  'Observation value'  as domain,
        NULL as "#Codes Source",
        NULL as "#Codes Mapped",
        NULL as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #obs_value
union all
select  'Provider Specialty'  as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #specialty
union all
select  'Condition status' as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #cond_status
union all
select  'Death cause'  as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #death_cause
union all
select  'Drug Route'  as domain,
        count_big(distinct source_value) as "#Codes Source",
        sum(is_mapped) as "#Codes Mapped",
        100.0*sum(is_mapped) / count_big(distinct source_value) as "%Codes Mapped",
        sum(num_records) as "#Records Source",
        sum(is_mapped * num_records) as "#Records Mapped",
        100.0*sum(is_mapped * num_records)/sum(num_records) as "%Records Mapped"
from #drug_route
;
