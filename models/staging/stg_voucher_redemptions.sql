{{ config(alias='stg_voucher_redemptions') }}

SELECT
    redemption_id,
    voucher_id,
    student_id,
    course_id,
    redemption_date,
    order_id,
    order_total,
    discount_applied,
    course_price_at_redemption,
    created_at
FROM {{ source('staging', 'raw_voucher_redemptions') }}
