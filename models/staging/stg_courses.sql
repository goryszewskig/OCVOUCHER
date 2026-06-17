{{ config(alias='stg_courses') }}

SELECT
    course_id,
    course_name,
    course_code,
    category,
    subcategory,
    instructor_name,
    price,
    currency,
    duration_hours,
    difficulty_level,
    is_published,
    created_at,
    updated_at
FROM {{ source('staging', 'raw_courses') }}
