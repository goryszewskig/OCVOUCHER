{{ config(alias='stg_students') }}

SELECT
    student_id,
    email,
    first_name,
    last_name,
    country,
    city,
    registration_date,
    is_active,
    created_at
FROM {{ source('staging', 'raw_students') }}
