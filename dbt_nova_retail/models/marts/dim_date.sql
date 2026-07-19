with spine as (
    select date_day
    from unnest(
        generate_date_array('2023-01-01', '2027-12-31', interval 1 day)
    ) as date_day
)

select
    cast(format_date('%Y%m%d', date_day) as int64) as date_key,
    date_day as date,
    extract(year from date_day) as year,
    extract(month from date_day) as month,
    extract(day from date_day) as day,
    extract(dayofweek from date_day) as day_of_week,
    extract(dayofweek from date_day) in (1, 7) as is_weekend
from spine
