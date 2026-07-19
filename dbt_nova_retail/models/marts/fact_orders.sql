select
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_key,
    o.order_id,
    c.customer_key,
    o.order_ts,
    o.order_date,
    o.status,
    o.total_amount
from {{ ref('stg_orders') }} o
left join {{ ref('dim_customers') }} c
    on o.customer_id = c.customer_id