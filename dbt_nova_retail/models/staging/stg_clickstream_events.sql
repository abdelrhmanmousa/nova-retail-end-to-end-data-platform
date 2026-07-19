with ranked as (
    select
        event_id,
        customer_id,
        session_id,
        event_type,
        product_id,
        device,
        timestamp(timestamp) as event_ts,
        date(timestamp(timestamp)) as event_date,
        row_number() over (
            partition by event_id
            order by ingestion_timestamp desc
        ) as rn
    from {{ source('raw_files', 'clickstream_events') }}
)

select
    event_id,
    customer_id,
    session_id,
    event_type,
    product_id,
    device,
    event_ts,
    event_date
from ranked
where rn = 1