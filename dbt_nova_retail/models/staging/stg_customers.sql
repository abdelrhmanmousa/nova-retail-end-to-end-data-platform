select
    customer_id,
    name,
    email,
    country,
    signup_date
from {{ source('datastream_cdc', 'customers') }}
-- CI test
