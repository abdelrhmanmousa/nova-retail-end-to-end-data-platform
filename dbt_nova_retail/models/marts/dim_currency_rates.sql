select
    {{ dbt_utils.generate_surrogate_key(['currency_code']) }} as currency_key,
    currency_code,
    rate_to_usd,
    fetched_at
from {{ ref('stg_currency_rates') }}
