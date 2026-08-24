select
    customer_id,
    order_date,
    count(*) as c
from {{ ref('stg_jaffle_shop__orders')}}
group by 1, 2