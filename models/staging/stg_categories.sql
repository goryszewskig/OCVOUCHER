{{ config(alias='stg_categories') }}

SELECT
    category_id,
    category_name,
    parent_category_id,
    level,
    path,
    created_at
FROM {{ source('staging', 'raw_categories') }}
