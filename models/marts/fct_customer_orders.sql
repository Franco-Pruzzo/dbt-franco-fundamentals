with

customers as (

    select * from {{ ref('stg_customers') }}

),

paid_orders as (

    select * from {{ ref('int_orders') }}

),

-- 1, 2, 3 y 4. CTE customer_orders uniendo órdenes con clientes y usando Window Functions
customer_orders as (

    select
        paid_orders.*,
        customers.first_name,
        customers.last_name,

        -- Contar total de órdenes del cliente
        count(*) over (
            partition by paid_orders.customer_id
        ) as order_count,

        -- Sumar solo las órdenes válidas (no devueltas / no fallidas)
        sum(if(paid_orders.order_status not in ('returned', 'pending'), 1, 0)) over (
            partition by paid_orders.customer_id
        ) as non_returned_order_count,

        -- Sumar el valor acumulado de órdenes válidas
        sum(if(paid_orders.order_status not in ('returned', 'pending'), paid_orders.total_amount_paid, 0)) over (
            partition by paid_orders.customer_id
        ) as total_lifetime_value

    from paid_orders
    left join customers on paid_orders.customer_id = customers.customer_id

),

-- 4. CTE para calcular el promedio sin romper las Window Functions previas
add_avg_order_values as (

    select
        *,
        total_lifetime_value / nullif(non_returned_order_count, 0) as avg_non_returned_order_value

    from customer_orders

),

-- 6. CTE final alineada con los nombres y orden requeridos para auditar
final as (

    select
        order_id,
        customer_id,
        order_date,
        order_status,
        total_amount_paid,
        payment_finalized_date,
        first_name,
        last_name,

        -- Secuencias y Métricas
        row_number() over (
            order by order_date, order_id
        ) as transaction_seq,

        row_number() over (
            partition by customer_id
            order by order_date, order_id
        ) as customer_sales_seq,

        case 
            when (
                rank() over (
                    partition by customer_id
                    order by order_date, order_id
                ) = 1
            ) then 'new'
            else 'return' 
        end as nvsr,

        sum(total_amount_paid) over (
            partition by customer_id
            order by order_date, order_id
        ) as customer_lifetime_value,

        first_value(order_date) over (
            partition by customer_id
            order by order_date, order_id
        ) as fdos

    from add_avg_order_values

)

select * from final