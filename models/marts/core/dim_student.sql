{{ config(alias='dim_student') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['s.student_id']) }} AS student_key,
    s.student_id,
    s.email,
    s.first_name,
    s.last_name,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    s.country,
    s.city,
    s.registration_date,
    s.is_active,
    YEAR(s.registration_date) AS registration_year,
    MONTH(s.registration_date) AS registration_month,
    CASE
        WHEN s.is_active = TRUE THEN 'Active'
        ELSE 'Inactive'
    END AS student_status,
    YEAR(CURDATE()) - YEAR(s.registration_date) AS tenure_years,
    s.created_at AS dbt_updated_at
FROM {{ ref('stg_students') }} s
