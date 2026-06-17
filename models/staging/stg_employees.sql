{{ config(alias='stg_employees') }}

SELECT
    employee_id,
    email,
    first_name,
    last_name,
    department_id,
    manager_id,
    job_title,
    hire_date,
    salary,
    is_active,
    level,
    created_at
FROM {{ source('staging', 'raw_employees') }}
