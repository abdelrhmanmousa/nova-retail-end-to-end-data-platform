select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,
    customer_id,
    name,
    email,
    country,
    signup_date
from {{ ref('stg_customers') }}
