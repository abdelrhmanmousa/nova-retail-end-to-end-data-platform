with ranked as (
    select
        product_id,
        supplier_id,
        stock_level,
        unit_cost_usd,
        timestamp(updated_at) as updated_at,
        row_number() over (
            partition by product_id
            order by timestamp(updated_at) desc
        ) as rn
    from {{ source('raw_files', 'supplier_catalog') }}
)

select
    product_id,
    supplier_id,
    stock_level,
    unit_cost_usd,
    updated_at
from ranked
where rn = 1
