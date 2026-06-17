{{ config(alias='stg_departments') }}

SELECT
    department_id,
    department_name,
    division_id,
    created_at
FROM {{ source('staging', 'raw_departments') }}
