with ranked as (
    select
        currency_code,
        rate_to_usd,
        timestamp(fetched_at) as fetched_at,
        row_number() over (
            partition by currency_code
            order by timestamp(fetched_at) desc
        ) as rn
    from {{ source('raw_files', 'currency_rates') }}
)

select
    currency_code,
    rate_to_usd,
    fetched_at
from ranked
where rn = 1
