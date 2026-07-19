select
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} as event_key,
    ce.event_id,
    c.customer_key,
    p.product_key,
    ce.session_id,
    ce.event_type,
    ce.device,
    ce.event_ts,
    ce.event_date
from {{ ref('stg_clickstream_events') }} ce
left join {{ ref('dim_customers') }} c
    on ce.customer_id = c.customer_id
left join {{ ref('dim_products') }} p
    on ce.product_id = p.product_id