-- =============================================================
-- SAMPLE DATASET WITH REALISTIC FRAUD SCENARIOS
-- =============================================================

USE electricity_fraud_db;


INSERT INTO locality_average (city, avg_monthly_units, peak_season_units, off_peak_units, total_customers) VALUES
('Mumbai', 450.00, 650.00, 350.00, 25),
('Delhi', 520.00, 750.00, 400.00, 30),
('Bangalore', 380.00, 550.00, 280.00, 20),
('Chennai', 490.00, 700.00, 380.00, 25),
('Hyderabad', 420.00, 600.00, 320.00, 22),
('Pune', 400.00, 580.00, 310.00, 18);


INSERT INTO customers (name, address, city, meter_type, connection_date, phone, email) VALUES
-- Normal Customers (1-10)
('Rajesh Kumar', '123 MG Road', 'Mumbai', 'residential', '2020-01-15', '9876543210', 'rajesh@email.com'),
('Priya Sharma', '456 Park Street', 'Delhi', 'residential', '2019-05-20', '9876543211', 'priya@email.com'),
('Amit Patel', '789 Ring Road', 'Bangalore', 'commercial', '2021-03-10', '9876543212', 'amit@email.com'),
('Sunita Reddy', '321 Anna Salai', 'Chennai', 'residential', '2020-08-25', '9876543213', 'sunita@email.com'),
('Vikram Singh', '654 Jubilee Hills', 'Hyderabad', 'residential', '2019-12-01', '9876543214', 'vikram@email.com'),
('Meera Joshi', '987 FC Road', 'Pune', 'residential', '2020-06-15', '9876543215', 'meera@email.com'),
('Ravi Gupta', '147 Sector 21', 'Delhi', 'commercial', '2021-01-30', '9876543216', 'ravi@email.com'),
('Kavya Nair', '258 Brigade Road', 'Bangalore', 'residential', '2020-04-12', '9876543217', 'kavya@email.com'),
('Deepak Shah', '369 Linking Road', 'Mumbai', 'residential', '2019-11-08', '9876543218', 'deepak@email.com'),
('Anita Desai', '741 Boat Club Road', 'Pune', 'residential', '2020-09-22', '9876543219', 'anita@email.com'),

-- Suspicious/Fraud Customers (11-20)
('Suspicious Co Ltd', '852 Industrial Area', 'Mumbai', 'industrial', '2021-02-14', '9876543220', 'suspicious@email.com'),
('Quick Mart', '963 Commercial Complex', 'Delhi', 'commercial', '2020-07-18', '9876543221', 'quickmart@email.com'),
('Shady Enterprises', '159 Tech Park', 'Bangalore', 'industrial', '2019-10-05', '9876543222', 'shady@email.com'),
('Dodgy Restaurant', '357 Food Street', 'Chennai', 'commercial', '2020-03-28', '9876543223', 'dodgy@email.com'),
('Fraud Factory', '486 HITEC City', 'Hyderabad', 'industrial', '2021-05-16', '9876543224', 'fraud@email.com'),
('Tamper Singh', '628 Old City', 'Delhi', 'residential', '2020-01-09', '9876543225', 'tamper@email.com'),
('Rollback Roy', '739 Whitefield', 'Bangalore', 'residential', '2019-08-13', '9876543226', 'rollback@email.com'),
('Spike Spotter', '840 T Nagar', 'Chennai', 'residential', '2020-11-07', '9876543227', 'spike@email.com'),
('Zero Usage Co', '951 Banjara Hills', 'Hyderabad', 'commercial', '2021-04-21', '9876543228', 'zero@email.com'),
('Constant Consumer', '162 Koregaon Park', 'Pune', 'residential', '2020-12-03', '9876543229', 'constant@email.com');



-- Normal consumption patterns (Customers 1-10)
INSERT INTO consumption (customer_id, reading_month, units_consumed, previous_units, bill_amount, reading_timestamp, reading_status) VALUES

-- Customer 1: Rajesh Kumar (Normal residential - Mumbai)
(1, '2024-01-01', 420.00, 0, 2520.00, '2024-01-31 10:30:00', 'actual'),
(1, '2024-02-01', 445.00, 420.00, 2670.00, '2024-02-29 11:15:00', 'actual'),
(1, '2024-03-01', 465.00, 445.00, 2790.00, '2024-03-31 09:45:00', 'actual'),
(1, '2024-04-01', 520.00, 465.00, 3120.00, '2024-04-30 14:20:00', 'actual'),
(1, '2024-05-01', 580.00, 520.00, 3480.00, '2024-05-31 10:10:00', 'actual'),
(1, '2024-06-01', 650.00, 580.00, 3900.00, '2024-06-30 12:30:00', 'actual'),
(1, '2024-07-01', 680.00, 650.00, 4080.00, '2024-07-31 11:45:00', 'actual'),
(1, '2024-08-01', 670.00, 680.00, 4020.00, '2024-08-31 13:15:00', 'actual'),
(1, '2024-09-01', 590.00, 670.00, 3540.00, '2024-09-30 10:20:00', 'actual'),
(1, '2024-10-01', 480.00, 590.00, 2880.00, '2024-10-31 15:30:00', 'actual'),
(1, '2024-11-01', 440.00, 480.00, 2640.00, '2024-11-30 09:50:00', 'actual'),
(1, '2024-12-01', 425.00, 440.00, 2550.00, '2024-12-31 14:10:00', 'actual'),

-- Customer 2: Priya Sharma (Normal residential - Delhi)
(2, '2024-01-01', 480.00, 0, 2880.00, '2024-01-31 11:00:00', 'actual'),
(2, '2024-02-01', 510.00, 480.00, 3060.00, '2024-02-29 10:30:00', 'actual'),
(2, '2024-03-01', 540.00, 510.00, 3240.00, '2024-03-31 12:15:00', 'actual'),
(2, '2024-04-01', 620.00, 540.00, 3720.00, '2024-04-30 09:45:00', 'actual'),
(2, '2024-05-01', 720.00, 620.00, 4320.00, '2024-05-31 14:20:00', 'actual'),
(2, '2024-06-01', 780.00, 720.00, 4680.00, '2024-06-30 11:30:00', 'actual'),
(2, '2024-07-01', 810.00, 780.00, 4860.00, '2024-07-31 13:45:00', 'actual'),
(2, '2024-08-01', 790.00, 810.00, 4740.00, '2024-08-31 10:15:00', 'actual'),
(2, '2024-09-01', 680.00, 790.00, 4080.00, '2024-09-30 12:30:00', 'actual'),
(2, '2024-10-01', 560.00, 680.00, 3360.00, '2024-10-31 09:20:00', 'actual'),
(2, '2024-11-01', 520.00, 560.00, 3120.00, '2024-11-30 15:10:00', 'actual'),
(2, '2024-12-01', 500.00, 520.00, 3000.00, '2024-12-31 11:45:00', 'actual');



-- Customer 11: Suspicious Co Ltd (SUDDEN SPIKE FRAUD)
INSERT INTO consumption (customer_id, reading_month, units_consumed, previous_units, bill_amount, reading_timestamp, reading_status) VALUES
(11, '2024-01-01', 1200.00, 0, 14400.00, '2024-01-31 10:00:00', 'actual'),
(11, '2024-02-01', 1250.00, 1200.00, 15000.00, '2024-02-29 11:00:00', 'actual'),
(11, '2024-03-01', 1180.00, 1250.00, 14160.00, '2024-03-31 12:00:00', 'actual'),
(11, '2024-04-01', 4800.00, 1180.00, 57600.00, '2024-04-30 13:00:00', 'actual'), -- 4x SPIKE
(11, '2024-05-01', 4950.00, 4800.00, 59400.00, '2024-05-31 14:00:00', 'actual'),
(11, '2024-06-01', 1100.00, 4950.00, 13200.00, '2024-06-30 15:00:00', 'actual'), -- Back to normal
(11, '2024-07-01', 1150.00, 1100.00, 13800.00, '2024-07-31 10:30:00', 'actual'),
(11, '2024-08-01', 5200.00, 1150.00, 62400.00, '2024-08-31 11:30:00', 'actual'), -- Another spike
(11, '2024-09-01', 1080.00, 5200.00, 12960.00, '2024-09-30 12:30:00', 'actual'),
(11, '2024-10-01', 1120.00, 1080.00, 13440.00, '2024-10-31 13:30:00', 'actual'),
(11, '2024-11-01', 1090.00, 1120.00, 13080.00, '2024-11-30 14:30:00', 'actual'),
(11, '2024-12-01', 6100.00, 1090.00, 73200.00, '2024-12-31 15:30:00', 'actual'); -- Year-end spike


INSERT INTO consumption (customer_id, reading_month, units_consumed, previous_units, bill_amount, reading_timestamp, reading_status) VALUES
(16, '2024-01-01', 450.00, 0, 2700.00, '2024-01-31 10:00:00', 'actual'),
(16, '2024-02-01', 480.00, 450.00, 2880.00, '2024-02-29 11:00:00', 'actual'),
(16, '2024-03-01', -50.00, 480.00, -300.00, '2024-03-31 12:00:00', 'actual'), -- ROLLBACK
(16, '2024-04-01', 520.00, -50.00, 3120.00, '2024-04-30 13:00:00', 'actual'),
(16, '2024-05-01', -80.00, 520.00, -480.00, '2024-05-31 14:00:00', 'actual'), -- Another rollback
(16, '2024-06-01', 580.00, -80.00, 3480.00, '2024-06-30 15:00:00', 'actual'),
(16, '2024-07-01', 600.00, 580.00, 3600.00, '2024-07-31 10:30:00', 'actual'),
(16, '2024-08-01', -120.00, 600.00, -720.00, '2024-08-31 11:30:00', 'actual'), -- Major rollback
(16, '2024-09-01', 540.00, -120.00, 3240.00, '2024-09-30 12:30:00', 'actual'),
(16, '2024-10-01', 490.00, 540.00, 2940.00, '2024-10-31 13:30:00', 'actual'),
(16, '2024-11-01', -30.00, 490.00, -180.00, '2024-11-30 14:30:00', 'actual'), -- Rollback again
(16, '2024-12-01', 470.00, -30.00, 2820.00, '2024-12-31 15:30:00', 'actual');

-- Customer 20: Constant Consumer (SAME USAGE EVERY MONTH - Suspicious!)
INSERT INTO consumption (customer_id, reading_month, units_consumed, previous_units, bill_amount, reading_timestamp, reading_status) VALUES
(20, '2024-01-01', 300.00, 0, 1800.00, '2024-01-31 10:00:00', 'actual'),
(20, '2024-02-01', 300.00, 300.00, 1800.00, '2024-02-29 11:00:00', 'actual'), -- Exactly same
(20, '2024-03-01', 300.00, 300.00, 1800.00, '2024-03-31 12:00:00', 'actual'), -- Exactly same
(20, '2024-04-01', 300.00, 300.00, 1800.00, '2024-04-30 13:00:00', 'actual'), -- Exactly same
(20, '2024-05-01', 300.00, 300.00, 1800.00, '2024-05-31 14:00:00', 'actual'), -- Exactly same
(20, '2024-06-01', 300.00, 300.00, 1800.00, '2024-06-30 15:00:00', 'actual'), -- Exactly same
(20, '2024-07-01', 300.00, 300.00, 1800.00, '2024-07-31 10:30:00', 'actual'), -- Exactly same
(20, '2024-08-01', 300.00, 300.00, 1800.00, '2024-08-31 11:30:00', 'actual'), -- Exactly same
(20, '2024-09-01', 300.00, 300.00, 1800.00, '2024-09-30 12:30:00', 'actual'), -- Exactly same
(20, '2024-10-01', 300.00, 300.00, 1800.00, '2024-10-31 13:30:00', 'actual'), -- Exactly same
(20, '2024-11-01', 300.00, 300.00, 1800.00, '2024-11-30 14:30:00', 'actual'), -- Exactly same
(20, '2024-12-01', 300.00, 300.00, 1800.00, '2024-12-31 15:30:00', 'actual'); -- Exactly same


SELECT 'Dataset Summary' as Info;
SELECT COUNT(*) as total_customers FROM customers;
SELECT COUNT(*) as total_consumption_records FROM consumption;
SELECT COUNT(*) as total_localities FROM locality_average;
SELECT MIN(reading_month) as earliest_reading, MAX(reading_month) as latest_reading FROM consumption;
SELECT AVG(units_consumed) as avg_consumption, MAX(units_consumed) as max_consumption, MIN(units_consumed) as min_consumption FROM consumption;