{{ config(alias='dim_employee_recursive') }}

WITH RECURSIVE employee_hierarchy AS (
    SELECT
        e.employee_id,
        e.email,
        e.first_name,
        e.last_name,
        CONCAT(e.first_name, ' ', e.last_name) AS full_name,
        e.department_id,
        e.manager_id,
        e.job_title,
        e.hire_date,
        e.salary,
        e.is_active,
        e.level AS org_level,
        CAST(e.employee_id AS CHAR(1000)) AS path_string,
        CAST(e.full_name AS CHAR(500)) AS hierarchy_path,
        1 AS depth,
        e.employee_id AS root_employee_id
    FROM {{ ref('stg_employees') }} e
    WHERE e.manager_id IS NULL

    UNION ALL

    SELECT
        e.employee_id,
        e.email,
        e.first_name,
        e.last_name,
        CONCAT(e.first_name, ' ', e.last_name) AS full_name,
        e.department_id,
        e.manager_id,
        e.job_title,
        e.hire_date,
        e.salary,
        e.is_active,
        e.level,
        CONCAT(h.path_string, '->', CAST(e.employee_id AS CHAR(50))) AS path_string,
        CONCAT(h.hierarchy_path, ' / ', e.full_name) AS hierarchy_path,
        h.depth + 1,
        h.root_employee_id
    FROM {{ ref('stg_employees') }} e
    INNER JOIN employee_hierarchy h ON e.manager_id = h.employee_id
),
manager_latest AS (
    SELECT
        employee_id,
        full_name,
        job_title,
        department_id,
        ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY depth ASC) AS rn
    FROM employee_hierarchy
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['e.employee_id']) }} AS employee_key,
    e.employee_id,
    e.email,
    e.first_name,
    e.last_name,
    e.full_name,
    e.department_id,
    d.department_name AS department_name,
    d.division_id,
    div.division_name AS division_name,
    e.manager_id,
    m.full_name AS manager_name,
    m.job_title AS manager_title,
    m.department_id AS manager_department_id,
    e.job_title,
    e.hire_date,
    e.salary,
    e.is_active,
    CASE WHEN e.is_active THEN 'Active' ELSE 'Inactive' END AS employee_status,
    e.org_level,
    e.depth,
    e.hierarchy_path,
    e.path_string,
    CASE
        WHEN e.depth = 1 THEN 'C-Level'
        WHEN e.depth = 2 THEN 'VP/Director'
        WHEN e.depth = 3 THEN 'Manager'
        WHEN e.depth = 4 THEN 'Senior'
        ELSE 'Junior'
    END AS level_title,
    YEAR(CURDATE()) - YEAR(e.hire_date) AS tenure_years,
    e.root_employee_id,
    (SELECT full_name FROM employee_hierarchy WHERE employee_id = e.root_employee_id) AS top_leader_name
FROM employee_hierarchy e
LEFT JOIN manager_latest m ON e.manager_id = m.employee_id AND m.rn = 1
LEFT JOIN {{ ref('stg_departments') }} d ON e.department_id = d.department_id
LEFT JOIN {{ ref('stg_divisions') }} div ON d.division_id = div.division_id
