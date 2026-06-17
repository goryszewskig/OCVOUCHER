{{ config(alias='dim_date') }}

WITH RECURSIVE date_range AS (
    SELECT DATE('2020-01-01') AS date_key
    UNION ALL
    SELECT DATE_ADD(date_key, INTERVAL 1 DAY)
    FROM date_range
    WHERE date_key < DATE('2030-12-31')
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['date_key']) }} AS date_key,
    date_key AS full_date,
    YEAR(date_key) AS year,
    MONTH(date_key) AS month,
    DAY(date_key) AS day,
    QUARTER(date_key) AS quarter,
    DAYOFWEEK(date_key) AS day_of_week,
    DAYNAME(date_key) AS day_name,
    MONTHNAME(date_key) AS month_name,
    DATE_FORMAT(date_key, '%Y-%m') AS year_month,
    CONCAT(YEAR(date_key), '-Q', QUARTER(date_key)) AS year_quarter,
    WEEK(date_key) AS week_of_year,
    DAYOFYEAR(date_key) AS day_of_year,
    CASE
        WHEN MONTH(date_key) IN (1, 2, 3) THEN 'Q1'
        WHEN MONTH(date_key) IN (4, 5, 6) THEN 'Q2'
        WHEN MONTH(date_key) IN (7, 8, 9) THEN 'Q3'
        ELSE 'Q4'
    END AS fiscal_quarter,
    CASE
        WHEN MONTH(date_key) <= 6 THEN 'H1'
        ELSE 'H2'
    END AS fiscal_half,
    IF(DAYOFWEEK(date_key) IN (1, 7), TRUE, FALSE) AS is_weekend,
    IF(date_key <= CURDATE(), TRUE, FALSE) AS is_past,
    IF(date_key = CURDATE(), TRUE, FALSE) AS is_today,
    IF(date_key = DATE_ADD(CURDATE(), INTERVAL 1 DAY), TRUE, FALSE) AS is_tomorrow,
    IF(date_key = DATE_ADD(CURDATE(), INTERVAL -1 DAY), TRUE, FALSE) AS is_yesterday
FROM date_range
