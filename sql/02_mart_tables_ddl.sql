-- MySQL 8.0 DDL for Voucher System - Analytics Mart Tables
-- These tables are created by dbt as part of the mart schema

CREATE DATABASE IF NOT EXISTS analytics;
USE analytics;

-- Note: Tables will be created by dbt based on model definitions
-- This file documents the expected structure

-- dim_voucher will be created as:
/*
CREATE TABLE dim_voucher (
    voucher_key VARCHAR(32) NOT NULL PRIMARY KEY,
    voucher_id INT NOT NULL,
    voucher_code VARCHAR(50) NOT NULL,
    voucher_type VARCHAR(20) NOT NULL,
    discount_type VARCHAR(20) NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    max_uses INT NULL,
    current_uses INT NOT NULL,
    min_order_value DECIMAL(10, 2) NULL,
    valid_from DATE NOT NULL,
    valid_until DATE NOT NULL,
    is_active BOOLEAN NOT NULL,
    voucher_status VARCHAR(20) NOT NULL,
    availability_status VARCHAR(20) NOT NULL,
    validity_days INT NULL,
    days_until_expiry INT NULL,
    remaining_uses INT NULL,
    dbt_updated_at TIMESTAMP NULL
);
*/

-- dim_course will be created as:
/*
CREATE TABLE dim_course (
    course_key VARCHAR(32) NOT NULL PRIMARY KEY,
    course_id INT NOT NULL,
    course_name VARCHAR(255) NOT NULL,
    course_code VARCHAR(50) NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100) NULL,
    instructor_name VARCHAR(255) NOT NULL,
    current_price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    duration_hours INT NOT NULL,
    difficulty_level VARCHAR(20) NOT NULL,
    course_status VARCHAR(20) NOT NULL,
    difficulty_sort_order INT NOT NULL,
    dbt_updated_at TIMESTAMP NULL
);
*/

-- dim_student will be created as:
/*
CREATE TABLE dim_student (
    student_key VARCHAR(32) NOT NULL PRIMARY KEY,
    student_id INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    full_name VARCHAR(201) NOT NULL,
    country VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    registration_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL,
    student_status VARCHAR(20) NOT NULL,
    tenure_years INT NOT NULL,
    dbt_updated_at TIMESTAMP NULL
);
*/

-- fact_voucher_redemption will be created as:
/*
CREATE TABLE fact_voucher_redemption (
    voucher_redemption_key VARCHAR(32) NOT NULL PRIMARY KEY,
    redemption_id INT NOT NULL,
    voucher_key VARCHAR(32) NOT NULL,
    student_key VARCHAR(32) NOT NULL,
    course_key VARCHAR(32) NOT NULL,
    redemption_date_key VARCHAR(32) NOT NULL,
    redemption_date DATE NOT NULL,
    order_id INT NOT NULL,
    order_total DECIMAL(10, 2) NOT NULL,
    discount_applied DECIMAL(10, 2) NOT NULL,
    course_price_at_redemption DECIMAL(10, 2) NOT NULL,
    net_course_price DECIMAL(10, 2) NOT NULL,
    was_discounted BOOLEAN NOT NULL,
    discount_percentage DECIMAL(10, 2) NULL,
    redemption_year INT NOT NULL,
    redemption_month INT NOT NULL,
    redemption_quarter INT NOT NULL,
    redemption_day_of_week INT NOT NULL,
    dbt_created_at TIMESTAMP NULL
);
*/

-- dim_date will be created as:
/*
CREATE TABLE dim_date (
    date_key VARCHAR(32) NOT NULL PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT NOT NULL,
    month INT NOT NULL,
    day INT NOT NULL,
    quarter INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    year_month VARCHAR(7) NOT NULL,
    year_quarter VARCHAR(8) NOT NULL,
    week_of_year INT NOT NULL,
    day_of_year INT NOT NULL,
    fiscal_quarter VARCHAR(2) NOT NULL,
    fiscal_half VARCHAR(2) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_past BOOLEAN NOT NULL,
    is_today BOOLEAN NOT NULL,
    is_tomorrow BOOLEAN NOT NULL,
    is_yesterday BOOLEAN NOT NULL
);
*/
