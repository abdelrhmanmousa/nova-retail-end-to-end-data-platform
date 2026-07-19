select
    product_id,
    name as product_name,
    category,
    base_price_usd,
    supplier_id
from {{ source('datastream_cdc', 'products') }}
