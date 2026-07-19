select
     {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,   -- Primary Key for this dimension
    p.product_id,
    p.product_name,
    p.category,
    p.base_price_usd,
    p.supplier_id,
    s.stock_level,
    s.unit_cost_usd as current_supplier_cost_usd,
    s.updated_at as supplier_data_updated_at
from {{ ref('stg_products') }} p
left join {{ ref('stg_supplier_catalog') }} s
    on p.product_id = s.product_id