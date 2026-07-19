select
    payment_id,
    order_id,
    payment_method,
    paid_ts,
    date(paid_ts) as paid_date,
    amount
from {{ source('datastream_cdc', 'payments') }}
