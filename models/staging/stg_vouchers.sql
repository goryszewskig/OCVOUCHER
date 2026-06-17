{{ config(alias='stg_vouchers') }}

SELECT
    voucher_id,
    voucher_code,
    voucher_type,
    discount_type,
    discount_value,
    max_uses,
    current_uses,
    min_order_value,
    valid_from,
    valid_until,
    is_active,
    created_at,
    updated_at
FROM {{ source('staging', 'raw_vouchers') }}
