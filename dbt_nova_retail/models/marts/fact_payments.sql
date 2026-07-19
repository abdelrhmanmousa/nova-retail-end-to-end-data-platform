select
    {{ dbt_utils.generate_surrogate_key(['payment_id']) }} as payment_key,
    pay.payment_id,
    o.order_key,
    pay.payment_method,
    pay.paid_ts,
    pay.paid_date,
    pay.amount
from {{ ref('stg_payments') }} pay
left join {{ ref('fact_orders') }} o
    on pay.order_id = o.order_id