{{ config(alias='dim_course_hierarchy_flat') }}

WITH category_tree AS (
    SELECT
        c.category_id,
        c.category_name,
        c.parent_category_id,
        p.category_name AS parent_category_name,
        1 AS level
    FROM {{ ref('stg_categories') }} c
    LEFT JOIN {{ ref('stg_categories') }} p ON c.parent_category_id = p.category_id

    UNION ALL

    SELECT
        ct.category_id,
        ct.category_name,
        ct.parent_category_id,
        ct.parent_category_name,
        ct.level + 1
    FROM category_tree ct
    WHERE ct.parent_category_id IS NOT NULL
),
course_hierarchy AS (
    SELECT
        co.course_id,
        co.course_name,
        co.course_code,
        co.category_id,
        co.subcategory_id,
        co.instructor_id,
        co.price,
        co.currency,
        co.duration_hours,
        co.difficulty_level,
        co.is_published,
        l3.category_name AS level3_category,
        l3.parent_category_name AS level2_category,
        (SELECT category_name FROM {{ ref('stg_categories') }} WHERE category_id = l3.parent_category_id) AS level1_category,
        co.created_at,
        co.updated_at
    FROM {{ ref('stg_courses') }} co
    LEFT JOIN category_tree l3 ON co.category_id = l3.category_id
      AND l3.level = (SELECT MAX(level) FROM category_tree WHERE category_id = co.category_id)
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['course_id']) }} AS course_hierarchy_key,
    course_id,
    course_name,
    course_code,
    category_id,
    level1_category AS category_l1,
    level2_category AS category_l2,
    level3_category AS category_l3,
    COALESCE(level1_category, level2_category, level3_category) AS primary_category,
    instructor_id,
    price AS current_price,
    currency,
    duration_hours,
    difficulty_level,
    CASE difficulty_level
        WHEN 'BEGINNER' THEN 1
        WHEN 'INTERMEDIATE' THEN 2
        WHEN 'ADVANCED' THEN 3
        ELSE 0
    END AS difficulty_level_num,
    is_published,
    CASE WHEN is_published THEN 'Published' ELSE 'Draft' END AS course_status,
    created_at,
    updated_at AS dbt_updated_at
FROM course_hierarchy
