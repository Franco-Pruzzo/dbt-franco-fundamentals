with raw_payments as (
    select * from  {{ source('stripe', 'payment') }}
),

renamed as (
    select
        id as payment_id,
        orderid as order_id,
        paymentmethod as payment_method,
        status as payment_status,
        {{ cents_to_dollars("amount",2) }} as payment_amount,
        created as created_at,
        _batched_at
        
    from raw_payments
)

select * from renamed