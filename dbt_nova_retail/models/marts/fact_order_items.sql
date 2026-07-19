select
    {{ dbt_utils.generate_surrogate_key(['order_item_id']) }} as order_item_key,
    oi.order_item_id,
    o.order_key,
    p.product_key,
    oi.quantity,
    oi.unit_price,
    oi.line_total
from {{ ref('stg_order_items') }} oi
left join {{ ref('fact_orders') }} o
    on oi.order_id = o.order_id
left join {{ ref('dim_products') }} p
    on oi.product_id = p.product_id