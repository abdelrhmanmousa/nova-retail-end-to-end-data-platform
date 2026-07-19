select
    order_id,
    customer_id,
    order_ts,
    date(order_ts) as order_date,
    status,
    total_amount
from {{ source('datastream_cdc', 'orders') }}
