with raw_payments as (
    select * from  {{ source('stripe', 'payment') }}
),

renamed as (
    select
        id as payment_id,
        orderid as order_id,
        paymentmethod as payment_method,
        status as payment_status,
        -- Lo dividimos por 100 para que la cuenta final te dé exacta
        amount / 100 as payment_amount,
        created as payment_created
    from raw_payments
)

select * from renamed