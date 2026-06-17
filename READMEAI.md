# Hierarchical Dimension flattening - Step by Step Guide

## Overview

This guide explains two approaches to handling hierarchical dimensions in Kimball modeling:

1. **Flattened Hierarchy** - Denormalized structure with fixed levels as columns
2. **Recursive Hierarchy** - Self-referencing structure using MySQL 8.0 recursive CTEs

## When to Use Each Approach

| Scenario | Recommended Approach |
|----------|---------------------|
| Fixed, known depth (e.g., 3-4 levels) | Flattened |
| Unknown/variable depth | Recursive |
| Frequent aggregations at each level | Flattened |
| Need full tree traversal | Recursive |
| Simple lookups | Flattened |
| Complex organizational charts | Recursive |

---

## Part 1: Flattened Hierarchy

### Use Case: Course Categories (3 levels)

**Business Requirement:** Categorize courses in a 3-level hierarchy:
```
IT → Programming → Python
IT → Programming → Java
Business → Marketing → Digital Marketing
```

### Step 1: Design the Source Table

```sql
-- Create category table with parent reference
CREATE TABLE raw_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id INT NULL,  -- NULL = root level
    level INT NOT NULL DEFAULT 1,  -- 1=L1, 2=L2, 3=L3
    path VARCHAR(500) NOT NULL DEFAULT '/',  -- Materialized path
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Sample Data:**
```sql
INSERT INTO raw_categories (category_id, category_name, parent_category_id, level, path) VALUES
(1, 'IT', NULL, 1, '/1/'),
(2, 'Programming', 1, 2, '/1/2/'),
(3, 'Python', 2, 3, '/1/2/3/'),
(4, 'Java', 2, 3, '/1/2/4/'),
(5, 'Business', NULL, 1, '/5/'),
(6, 'Marketing', 5, 2, '/5/6/'),
(7, 'Digital Marketing', 6, 3, '/5/6/7/');
```

### Step 2: Link Courses to Leaf Category

```sql
ALTER TABLE raw_courses ADD COLUMN subcategory_id INT;

INSERT INTO raw_courses (course_id, course_name, course_code, subcategory_id, price) VALUES
(1, 'Python Basics', 'PY101', 3, 99.99),
(2, 'Java Masterclass', 'JAVA201', 4, 149.99),
(3, 'Digital Marketing 101', 'DM101', 7, 79.99);
```

### Step 3: Create dbt Staging Model

```sql
-- models/staging/stg_categories.sql
{{ config(alias='stg_categories') }}

SELECT
    category_id,
    category_name,
    parent_category_id,
    level,
    path,
    created_at
FROM {{ source('staging', 'raw_categories') }}
```

### Step 4: Create Flattened Dimension Model

```sql
-- models/marts/hierarchical_flat/dim_course_hierarchy_flat.sql
{{ config(alias='dim_course_hierarchy_flat') }}

WITH category_tree AS (
    -- Base case: start with all categories
    SELECT
        c.category_id,
        c.category_name,
        c.parent_category_id,
        CAST(c.category_name AS CHAR(500)) AS path_names,
        1 AS level
    FROM {{ ref('stg_categories') }} c
    WHERE c.parent_category_id IS NULL

    UNION ALL

    -- Recursive case: join children
    SELECT
        c.category_id,
        c.category_name,
        c.parent_category_id,
        CONCAT(ct.path_names, ' / ', c.category_name),
        ct.level + 1
    FROM {{ ref('stg_categories') }} c
    INNER JOIN category_tree ct ON c.parent_category_id = ct.category_id
),
ranked_categories AS (
    -- Rank categories by depth for each leaf
    SELECT
        category_id,
        category_name,
        parent_category_id,
        level,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY level DESC) AS rn
    FROM category_tree
),
pivoted AS (
    -- Pivot to get L1, L2, L3 as separate columns
    SELECT
        category_id,
        MAX(CASE WHEN level = 1 THEN category_name END) AS category_l1,
        MAX(CASE WHEN level = 2 THEN category_name END) AS category_l2,
        MAX(CASE WHEN level = 3 THEN category_name END) AS category_l3
    FROM ranked_categories
    GROUP BY category_id
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['co.course_id']) }} AS course_hierarchy_key,
    co.course_id,
    co.course_name,
    co.course_code,
    co.category_id AS leaf_category_id,
    p.category_l1,
    p.category_l2,
    p.category_l3,
    COALESCE(p.category_l1, p.category_l2, p.category_l3) AS primary_category,
    co.price AS current_price,
    co.currency,
    co.duration_hours,
    co.difficulty_level,
    co.is_published,
    CASE WHEN co.is_published THEN 'Published' ELSE 'Draft' END AS course_status
FROM {{ ref('stg_courses') }} co
LEFT JOIN pivoted p ON co.subcategory_id = p.category_id
```

### Step 5: Result

| course_id | course_name | category_l1 | category_l2 | category_l3 | primary_category |
|-----------|-------------|-------------|-------------|-------------|------------------|
| 1 | Python Basics | IT | Programming | Python | IT |
| 2 | Java Masterclass | IT | Programming | Java | IT |
| 3 | Digital Marketing 101 | Business | Marketing | Digital Marketing | Business |

---

## Part 2: Recursive Hierarchy

### Use Case: Employee Organizational Chart

**Business Requirement:** Model unlimited depth org hierarchy with manager-employee relationships.

### Step 1: Design the Source Tables

```sql
-- Divisions
CREATE TABLE raw_divisions (
    division_id INT AUTO_INCREMENT PRIMARY KEY,
    division_name VARCHAR(100) NOT NULL
);

-- Departments (belong to division)
CREATE TABLE raw_departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    division_id INT NOT NULL,
    FOREIGN KEY (division_id) REFERENCES raw_divisions(division_id)
);

-- Employees (self-referencing for hierarchy)
CREATE TABLE raw_employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    department_id INT NOT NULL,
    manager_id INT NULL,  -- NULL = top level (CEO)
    job_title VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(12, 2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    level INT NOT NULL DEFAULT 1,
    FOREIGN KEY (department_id) REFERENCES raw_departments(department_id),
    FOREIGN KEY (manager_id) REFERENCES raw_employees(employee_id)
);
```

**Sample Data:**
```sql
-- Divisions
INSERT INTO raw_divisions (division_id, division_name) VALUES
(1, 'Technology'), (2, 'Sales');

-- Departments
INSERT INTO raw_departments (department_id, department_name, division_id) VALUES
(1, 'Engineering', 1), (2, 'Sales', 2);

-- Employees (org hierarchy)
INSERT INTO raw_employees (employee_id, first_name, last_name, department_id, manager_id, job_title, hire_date, salary, level) VALUES
(1, 'John', 'CEO', 1, NULL, 'Chief Executive Officer', '2015-01-01', 500000, 1),
(2, 'Jane', 'VP Engineering', 1, 1, 'VP of Engineering', '2016-03-15', 300000, 2),
(3, 'Bob', 'VP Sales', 2, 1, 'VP of Sales', '2016-06-01', 280000, 2),
(4, 'Alice', 'Engineering Manager', 1, 2, 'Engineering Manager', '2017-02-20', 180000, 3),
(5, 'Charlie', 'Senior Developer', 1, 4, 'Senior Developer', '2018-07-10', 150000, 4),
(6, 'Diana', 'Junior Developer', 1, 4, 'Junior Developer', '2020-01-15', 90000, 5),
(7, 'Eve', 'Sales Manager', 2, 3, 'Sales Manager', '2018-04-01', 140000, 3),
(8, 'Frank', 'Account Executive', 2, 7, 'Account Executive', '2019-09-20', 80000, 4);
```

**Resulting Hierarchy:**
```
John CEO (depth=1)
 ├── Jane VP Engineering (depth=2)
 │    ├── Alice Engineering Manager (depth=3)
 │    │    ├── Charlie Senior Developer (depth=4)
 │    │    └── Diana Junior Developer (depth=5)
 └── Bob VP Sales (depth=2)
      └── Eve Sales Manager (depth=3)
           └── Frank Account Executive (depth=4)
```

### Step 2: Create dbt Staging Models

```sql
-- models/staging/stg_divisions.sql
{{ config(alias='stg_divisions') }}
SELECT division_id, division_name, created_at
FROM {{ source('staging', 'raw_divisions') }}

-- models/staging/stg_departments.sql
{{ config(alias='stg_departments') }}
SELECT department_id, department_name, division_id, created_at
FROM {{ source('staging', 'raw_departments') }}

-- models/staging/stg_employees.sql
{{ config(alias='stg_employees') }}
SELECT employee_id, email, first_name, last_name, department_id,
       manager_id, job_title, hire_date, salary, is_active, level, created_at
FROM {{ source('staging', 'raw_employees') }}
```

### Step 3: Create Recursive Dimension Model

```sql
-- models/marts/hierarchical_recursive/dim_employee_recursive.sql
{{ config(alias='dim_employee_recursive') }}

WITH RECURSIVE employee_hierarchy AS (
    -- Base case: top-level employees (no manager)
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
        CAST(e.employee_id AS CHAR(1000)) AS path_ids,
        CAST(e.full_name AS CHAR(1000)) AS hierarchy_path,
        1 AS depth,
        e.employee_id AS root_employee_id
    FROM {{ ref('stg_employees') }} e
    WHERE e.manager_id IS NULL

    UNION ALL

    -- Recursive case: employees with managers
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
        CONCAT(h.path_ids, '->', CAST(e.employee_id AS CHAR(50))) AS path_ids,
        CONCAT(h.hierarchy_path, ' / ', e.full_name) AS hierarchy_path,
        h.depth + 1,
        h.root_employee_id
    FROM {{ ref('stg_employees') }} e
    INNER JOIN employee_hierarchy h ON e.manager_id = h.employee_id
)
SELECT
    {{ dbt_utils.generate_surrogate_key(['e.employee_id']) }} AS employee_key,
    e.employee_id,
    e.email,
    e.first_name,
    e.last_name,
    e.full_name,
    e.department_id,
    d.department_name,
    div.division_id,
    div.division_name,
    e.manager_id,
    m.full_name AS manager_name,
    m.job_title AS manager_job_title,
    e.job_title,
    e.hire_date,
    e.salary,
    e.is_active,
    CASE WHEN e.is_active THEN 'Active' ELSE 'Inactive' END AS employee_status,
    e.org_level,
    e.depth,
    e.hierarchy_path,
    e.path_ids,
    CASE
        WHEN e.depth = 1 THEN 'C-Level'
        WHEN e.depth = 2 THEN 'VP/Director'
        WHEN e.depth = 3 THEN 'Manager'
        WHEN e.depth = 4 THEN 'Senior'
        ELSE 'Junior'
    END AS level_title,
    YEAR(CURDATE()) - YEAR(e.hire_date) AS tenure_years,
    e.root_employee_id,
    top.root_name AS top_leader_name,
    top.root_title AS top_leader_title
FROM employee_hierarchy e
LEFT JOIN {{ ref('stg_departments') }} d ON e.department_id = d.department_id
LEFT JOIN {{ ref('stg_divisions') }} div ON d.division_id = div.division_id
LEFT JOIN employee_hierarchy m ON e.manager_id = m.employee_id
LEFT JOIN (
    SELECT employee_id AS root_id, full_name AS root_name, job_title AS root_title
    FROM employee_hierarchy
    WHERE depth = 1
) top ON e.root_employee_id = top.root_id
```

### Step 4: Result

| employee_id | full_name | depth | manager_name | hierarchy_path | level_title |
|------------|-----------|-------|--------------|----------------|-------------|
| 1 | John CEO | 1 | NULL | John CEO | C-Level |
| 2 | Jane VP Engineering | 2 | John CEO | John CEO / Jane VP Engineering | VP/Director |
| 5 | Charlie Senior Developer | 4 | Alice Engineering Manager | John CEO / Jane VP Engineering / Alice Engineering Manager / Charlie Senior Developer | Senior |
| 8 | Frank Account Executive | 4 | Eve Sales Manager | John CEO / Bob VP Sales / Eve Sales Manager / Frank Account Executive | Senior |

---

## Common Patterns & Best Practices

### 1. Finding All Descendants of a Node

```sql
-- Find all employees under Jane VP Engineering
SELECT * FROM dim_employee_recursive
WHERE path_ids LIKE '%->2->%' OR employee_id = 2;
```

### 2. Finding All Ancestors of a Node

```sql
-- Find management chain for Charlie
WITH RECURSIVE ancestors AS (
    SELECT employee_id, full_name, manager_id, 1 AS level
    FROM raw_employees WHERE employee_id = 5
    UNION ALL
    SELECT e.employee_id, e.full_name, e.manager_id, a.level + 1
    FROM raw_employees e
    INNER JOIN ancestors a ON e.employee_id = a.manager_id
)
SELECT * FROM ancestors ORDER BY level;
```

### 3. Counting Nodes at Each Level

```sql
SELECT depth, COUNT(*) AS employee_count
FROM dim_employee_recursive
GROUP BY depth
ORDER BY depth;
```

### 4. Materialized Path for Fast Lookups

```sql
-- Find all courses in IT category or subcategories
SELECT * FROM dim_course_hierarchy_flat
WHERE path LIKE '/1/%';
```

---

## Troubleshooting

### MySQL Recursive CTE Errors

**Error:** `Recursive CTE maximum recursion depth exceeded`

**Solution:** Add `MAX_RECURSIVE_ITERATIONS` hint:
```sql
WITH RECURSIVE employee_hierarchy AS (
    ...
)
SELECT /*+ MAX_RECURSIVE_ITERATIONS(1000) */ * FROM employee_hierarchy;
```

**Or set globally:**
```sql
SET SESSION max_recursive_iterations = 1000;
```

### Null Manager for Top Level

Always ensure top-level employees have `manager_id = NULL` for the base case to work.

### Circular References

Validate no circular references exist:
```sql
SELECT * FROM raw_employees e1
WHERE e1.manager_id = e1.employee_id;  -- Should return empty
```

---

## Performance Considerations

| Technique | Use Case |
|-----------|----------|
| Add index on `parent_category_id` | Faster hierarchy traversal |
| Add index on `manager_id` | Faster manager lookups |
| Materialized path column | Fast subtree queries |
| Limit recursion depth | Prevent runaway queries |

```sql
-- Recommended indexes
CREATE INDEX idx_parent ON raw_categories(parent_category_id);
CREATE INDEX idx_manager ON raw_employees(manager_id);
CREATE INDEX idx_path ON raw_categories(path);
```

---

## dbt Model Execution Order

```bash
# 1. Run staging models first
dbt run -s staging --target prod

# 2. Run hierarchical dimensions
dbt run -s hierarchical_flat hierarchical_recursive --target prod

# 3. Verify with tests
dbt test -s hierarchical_flat hierarchical_recursive --target prod
```

---

## Further Reading

- [Kimball Data Warehouse Toolkit](https://www.kimballgroup.com/books/)
- [MySQL 8.0 Recursive CTE Documentation](https://dev.mysql.com/doc/refman/8.0/en/with.html)
- [dbt_utils package](https://github.com/dbt-labs/dbt-utils)
