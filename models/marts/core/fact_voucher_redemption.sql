{{ config(alias='fact_voucher_redemption') }}

WITH redemptions AS (
    SELECT
        r.redemption_id,
        r.voucher_id,
        r.student_id,
        r.course_id,
        r.redemption_date,
        r.order_id,
        r.order_total,
        r.discount_applied,
        r.course_price_at_redemption,
        r.created_at,
        {{ dbt_utils.generate_surrogate_key(['r.voucher_id']) }} AS voucher_key,
        {{ dbt_utils.generate_surrogate_key(['r.student_id']) }} AS student_key,
        {{ dbt_utils.generate_surrogate_key(['r.course_id']) }} AS course_key,
        {{ dbt_utils.generate_surrogate_key(['r.redemption_date']) }} AS redemption_date_key
    FROM {{ ref('stg_voucher_redemptions') }} r
)
SELECT
    {{ dbt_utils.generate_surrogate_key([
        'redemption_id',
        'voucher_id',
        'student_id',
        'course_id',
        'redemption_date'
    ]) }} AS voucher_redemption_key,
    r.redemption_id,
    r.voucher_key,
    r.student_key,
    r.course_key,
    r.redemption_date_key,
    r.redemption_date,
    r.order_id,
    r.order_total,
    r.discount_applied,
    r.course_price_at_redemption,
    r.course_price_at_redemption - r.discount_applied AS net_course_price,
    IF(r.discount_applied > 0, TRUE, FALSE) AS was_discounted,
    CASE
        WHEN r.discount_applied = 0 THEN 'No Discount'
        WHEN r.discount_applied = r.course_price_at_redemption THEN 'Free'
        WHEN r.course_price_at_redemption > 0 THEN ROUND(r.discount_applied / r.course_price_at_redemption * 100, 2)
        ELSE 0
    END AS discount_percentage,
    YEAR(r.redemption_date) AS redemption_year,
    MONTH(r.redemption_date) AS redemption_month,
    QUARTER(r.redemption_date) AS redemption_quarter,
    DAYOFWEEK(r.redemption_date) AS redemption_day_of_week,
    r.created_at AS dbt_created_at
FROM redemptions r
