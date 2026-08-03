with raw as (
    select * from {{ source('jaffle_shop', 'customers') }}
),

transformed as (

    select
        id as customer_id,
        first_name,
        last_name
    from raw

)

select * from transformed
