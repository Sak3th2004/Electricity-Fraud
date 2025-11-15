




DROP DATABASE IF EXISTS electricity_fraud_db;
CREATE DATABASE electricity_fraud_db;
USE electricity_fraud_db;


-- TABLE 1: CUSTOMERS

CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    meter_type ENUM('residential', 'commercial', 'industrial') NOT NULL,
    connection_date DATE NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100),
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_city (city),
    INDEX idx_meter_type (meter_type)
);


-- TABLE 2: LOCALITY_AVERAGE

CREATE TABLE locality_average (
    locality_id INT PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(50) NOT NULL UNIQUE,
    avg_monthly_units DECIMAL(10,2) NOT NULL,
    peak_season_units DECIMAL(10,2) NOT NULL,
    off_peak_units DECIMAL(10,2) NOT NULL,
    total_customers INT DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_city_avg (city)
);


-- TABLE 3: CONSUMPTION

CREATE TABLE consumption (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    reading_month DATE NOT NULL,
    units_consumed DECIMAL(10,2) NOT NULL,
    previous_units DECIMAL(10,2) DEFAULT 0,
    bill_amount DECIMAL(10,2) NOT NULL,
    reading_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    meter_reader_id VARCHAR(20),
    reading_status ENUM('normal', 'estimated', 'actual') DEFAULT 'actual',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    INDEX idx_customer_month (customer_id, reading_month),
    INDEX idx_reading_month (reading_month),
    INDEX idx_units_consumed (units_consumed),
    UNIQUE KEY unique_customer_month (customer_id, reading_month)
);


-- TABLE 4: FRAUD_FLAGS

CREATE TABLE fraud_flags (
    fraud_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    reason VARCHAR(255) NOT NULL,
    month DATE NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    anomaly_score DECIMAL(5,2) DEFAULT 0,
    flag_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detected_by VARCHAR(50) DEFAULT 'system',
    status ENUM('open', 'investigating', 'resolved', 'false_positive') DEFAULT 'open',
    resolution_notes TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    INDEX idx_customer_fraud (customer_id),
    INDEX idx_severity (severity),
    INDEX idx_month (month),
    INDEX idx_status (status)
);


-- TRIGGERS FOR DATA INTEGRITY


-- Trigger to prevent negative consumption
DELIMITER //
CREATE TRIGGER prevent_negative_consumption 
BEFORE INSERT ON consumption
FOR EACH ROW
BEGIN
    IF NEW.units_consumed < 0 THEN
        INSERT INTO fraud_flags (customer_id, reason, month, severity, anomaly_score)
        VALUES (NEW.customer_id, 'Negative consumption detected', NEW.reading_month, 'high', 95.0);
    END IF;
END//
DELIMITER ;


-- INDEXES FOR PERFORMANCE

CREATE INDEX idx_consumption_analysis ON consumption(customer_id, reading_month, units_consumed);
CREATE INDEX idx_fraud_analysis ON fraud_flags(customer_id, severity, flag_date);


SHOW TABLES;
DESCRIBE customers;
DESCRIBE consumption;
DESCRIBE locality_average; 
DESCRIBE fraud_flags;