{{ config(alias='stg_divisions') }}

SELECT
    division_id,
    division_name,
    created_at
FROM {{ source('staging', 'raw_divisions') }}
