{{ config(alias='dim_course') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['c.course_id']) }} AS course_key,
    c.course_id,
    c.course_name,
    c.course_code,
    c.category,
    c.subcategory,
    c.instructor_name,
    c.price AS current_price,
    c.currency,
    c.duration_hours,
    c.difficulty_level,
    c.is_published,
    CASE
        WHEN c.is_published = TRUE THEN 'Published'
        ELSE 'Draft'
    END AS course_status,
    CASE
        WHEN c.difficulty_level = 'BEGINNER' THEN 1
        WHEN c.difficulty_level = 'INTERMEDIATE' THEN 2
        WHEN c.difficulty_level = 'ADVANCED' THEN 3
        ELSE 0
    END AS difficulty_sort_order,
    c.updated_at AS dbt_updated_at
FROM {{ ref('stg_courses') }} c
