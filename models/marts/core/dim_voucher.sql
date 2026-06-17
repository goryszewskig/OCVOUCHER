{{ config(alias='dim_voucher') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['v.voucher_id']) }} AS voucher_key,
    v.voucher_id,
    v.voucher_code,
    v.voucher_type,
    v.discount_type,
    v.discount_value,
    v.max_uses,
    v.current_uses,
    v.min_order_value,
    v.valid_from,
    v.valid_until,
    v.is_active,
    CASE
        WHEN v.is_active = TRUE AND v.valid_until >= CURDATE() THEN 'Active'
        WHEN v.is_active = TRUE AND v.valid_until < CURDATE() THEN 'Expired'
        ELSE 'Inactive'
    END AS voucher_status,
    CASE
        WHEN v.max_uses IS NULL THEN 'Unlimited'
        WHEN v.current_uses < v.max_uses THEN 'Available'
        ELSE 'Fully Redeemed'
    END AS availability_status,
    DATEDIFF(v.valid_until, v.valid_from) AS validity_days,
    DATEDIFF(v.valid_until, CURDATE()) AS days_until_expiry,
    IF(v.max_uses IS NULL, NULL, v.max_uses - v.current_uses) AS remaining_uses,
    v.updated_at AS dbt_updated_at
FROM {{ ref('stg_vouchers') }} v
