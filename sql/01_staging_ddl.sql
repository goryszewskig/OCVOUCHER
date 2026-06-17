-- MySQL 8.0 DDL for Voucher System - Staging Tables
-- Run this script to create source tables in your staging schema

CREATE DATABASE IF NOT EXISTS staging;
USE staging;

-- Vouchers source table
CREATE TABLE raw_vouchers (
    voucher_id INT AUTO_INCREMENT PRIMARY KEY,
    voucher_code VARCHAR(50) NOT NULL UNIQUE,
    voucher_type ENUM('SINGLE_USE', 'MULTI_USE', 'UNLIMITED') NOT NULL,
    discount_type ENUM('PERCENTAGE', 'FIXED_AMOUNT', 'FREE') NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    max_uses INT NULL,
    current_uses INT NOT NULL DEFAULT 0,
    min_order_value DECIMAL(10, 2) NULL,
    valid_from DATE NOT NULL,
    valid_until DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_voucher_code (voucher_code),
    INDEX idx_is_active (is_active),
    INDEX idx_valid_dates (valid_from, valid_until)
);

-- Courses source table
CREATE TABLE raw_courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_name VARCHAR(255) NOT NULL,
    course_code VARCHAR(50) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100) NULL,
    instructor_name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    duration_hours INT NOT NULL,
    difficulty_level ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED') NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_is_published (is_published)
);

-- Students source table
CREATE TABLE raw_students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    registration_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_country (country),
    INDEX idx_registration_date (registration_date)
);

-- Voucher Redemptions (Fact) source table
CREATE TABLE raw_voucher_redemptions (
    redemption_id INT AUTO_INCREMENT PRIMARY KEY,
    voucher_id INT NOT NULL,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    redemption_date DATE NOT NULL,
    order_id INT NOT NULL,
    order_total DECIMAL(10, 2) NOT NULL,
    discount_applied DECIMAL(10, 2) NOT NULL,
    course_price_at_redemption DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (voucher_id) REFERENCES raw_vouchers(voucher_id),
    FOREIGN KEY (student_id) REFERENCES raw_students(student_id),
    FOREIGN KEY (course_id) REFERENCES raw_courses(course_id),
    INDEX idx_redemption_date (redemption_date),
    INDEX idx_voucher_id (voucher_id),
    INDEX idx_student_id (student_id),
    INDEX idx_course_id (course_id)
);
