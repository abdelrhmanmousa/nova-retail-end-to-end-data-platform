-- This test will fail if it finds ANY rows.
-- We are looking for data bugs where the total is negative.
select
    order_id,
    total_amount
from {{ ref('stg_orders') }}
where total_amount < 0