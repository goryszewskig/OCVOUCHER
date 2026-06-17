# Voucher Analytics - dbt Kimball Model

Kimball-style dimensional data model for voucher-based course purchasing analytics.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ raw_students│     │ raw_courses │     │ raw_vouchers│
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│stg_students │     │ stg_courses │     │ stg_vouchers│
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│dim_student  │     │ dim_course  │     │ dim_voucher │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                   │
                           ▼                   │
                  ┌─────────────────────────────┤
                  │                             │
                  ▼                             ▼
         ┌─────────────────────┐      ┌─────────────┐
         │fact_voucher_redempti│      │  dim_date   │
         │   on (fact table)   │      └─────────────┘
         └─────────────────────┘
```

## Data Model

### Dimension Tables

| Table | Description |
|-------|-------------|
| `dim_voucher` | Voucher dimension with status, expiry tracking, remaining uses |
| `dim_course` | Course dimension with category, instructor, pricing |
| `dim_student` | Student dimension with demographics and tenure |
| `dim_date` | Date dimension with fiscal calendar attributes |

### Fact Table

| Table | Description |
|-------|-------------|
| `fact_voucher_redemption` | Transactional fact for voucher usage (many-to-many: one voucher → many courses) |

## Voucher Types Supported

- `SINGLE_USE` - One-time voucher
- `MULTI_USE` - Limited number of uses
- `UNLIMITED` - No use limit

## Discount Types

- `PERCENTAGE` - Percentage off
- `FIXED_AMOUNT` - Fixed monetary discount
- `FREE` - Completely free

## Prerequisites

- MySQL 8.0+
- dbt >= 1.6.0
- dbt-labs/dbt_utils

## Installation

```bash
cd dbt_voucher_model
dbt deps
```

## Setup Source Database

Run the DDL script to create staging tables:

```bash
mysql -u root -p < sql/01_staging_ddl.sql
```

## Running Models

```bash
# Run all models
dbt run

# Run specific model
dbt run -s dim_voucher

# Test models
dbt test

# Full cycle
dbt run && dbt test
```

## Key Metrics Available

- Voucher utilization rate
- Discount effectiveness (% of courses discounted)
- Course popularity by voucher type
- Student acquisition through vouchers
- Voucher expiry analysis
- Revenue impact of vouchers

## Example Queries

### Voucher Utilization
```sql
SELECT
    v.voucher_code,
    v.voucher_type,
    v.discount_type,
    COUNT(f.redemption_id) AS total_redemptions,
    SUM(f.discount_applied) AS total_discount
FROM fact_voucher_redemption f
JOIN dim_voucher v ON f.voucher_key = v.voucher_key
GROUP BY v.voucher_code, v.voucher_type, v.discount_type;
```

### Course Revenue Impact
```sql
SELECT
    c.course_name,
    c.category,
    COUNT(*) AS voucher_purchases,
    SUM(f.course_price_at_redemption) AS gross_revenue,
    SUM(f.discount_applied) AS total_discounts
FROM fact_voucher_redemption f
JOIN dim_course c ON f.course_key = c.course_key
GROUP BY c.course_name, c.category;
```

### Student Voucher Usage
```sql
SELECT
    s.full_name,
    s.country,
    COUNT(DISTINCT f.voucher_key) AS vouchers_used,
    SUM(f.discount_applied) AS total_savings
FROM fact_voucher_redemption f
JOIN dim_student s ON f.student_key = s.student_key
GROUP BY s.full_name, s.country;
```

## File Structure

```
dbt_voucher_model/
├── dbt_project.yml          # dbt configuration
├── packages.yml             # package dependencies
├── models/
│   ├── staging/             # Staging layer (views)
│   │   ├── staging.yml
│   │   ├── stg_vouchers.sql
│   │   ├── stg_courses.sql
│   │   ├── stg_students.sql
│   │   └── stg_voucher_redemptions.sql
│   └── marts/
│       └── core/            # Core mart layer (tables)
│           ├── core.yml
│           ├── dim_voucher.sql
│           ├── dim_course.sql
│           ├── dim_student.sql
│           ├── dim_date.sql
│           └── fact_voucher_redemption.sql
├── sql/
│   ├── 01_staging_ddl.sql   # Source table DDL
│   └── 02_mart_tables_ddl.sql
└── tests/
```

## Schema

- `staging` - Raw source data
- `analytics` - Final mart tables

## License

Internal use only.
