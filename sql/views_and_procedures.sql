

USE electricity_fraud_db;


CREATE OR REPLACE VIEW fraud_risk_dashboard AS
SELECT 
    c.customer_id,
    cu.name,
    cu.city,
    cu.meter_type,
    c.reading_month,
    c.units_consumed,
    c.previous_units,
    l.avg_monthly_units,
    
    -- Moving average using window function
    AVG(c.units_consumed) OVER (
        PARTITION BY c.customer_id 
        ORDER BY c.reading_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3month,
    
    -- Fraud risk score
    (CASE 
        WHEN c.units_consumed < 0 THEN 100
        WHEN c.units_consumed > 4 * NULLIF(c.previous_units, 0) THEN 95
        WHEN c.units_consumed > 3 * l.avg_monthly_units THEN 90
        WHEN c.units_consumed > 3 * NULLIF(c.previous_units, 0) THEN 85
        WHEN c.units_consumed < (0.3 * NULLIF(c.previous_units, 0)) THEN 80
        WHEN c.units_consumed > 2.5 * l.avg_monthly_units THEN 75
        WHEN c.units_consumed = c.previous_units THEN 70
        ELSE 20
    END) AS fraud_score,
    
    -- Risk level
    CASE 
        WHEN (CASE 
            WHEN c.units_consumed < 0 THEN 100
            WHEN c.units_consumed > 4 * NULLIF(c.previous_units, 0) THEN 95
            WHEN c.units_consumed > 3 * l.avg_monthly_units THEN 90
            WHEN c.units_consumed > 3 * NULLIF(c.previous_units, 0) THEN 85
            WHEN c.units_consumed < (0.3 * NULLIF(c.previous_units, 0)) THEN 80
            WHEN c.units_consumed > 2.5 * l.avg_monthly_units THEN 75
            WHEN c.units_consumed = c.previous_units THEN 70
            ELSE 20
        END) >= 80 THEN 'CRITICAL'
        WHEN (CASE 
            WHEN c.units_consumed < 0 THEN 100
            WHEN c.units_consumed > 4 * NULLIF(c.previous_units, 0) THEN 95
            WHEN c.units_consumed > 3 * l.avg_monthly_units THEN 90
            WHEN c.units_consumed > 3 * NULLIF(c.previous_units, 0) THEN 85
            WHEN c.units_consumed < (0.3 * NULLIF(c.previous_units, 0)) THEN 80
            WHEN c.units_consumed > 2.5 * l.avg_monthly_units THEN 75
            WHEN c.units_consumed = c.previous_units THEN 70
            ELSE 20
        END) >= 60 THEN 'HIGH'
        WHEN (CASE 
            WHEN c.units_consumed < 0 THEN 100
            WHEN c.units_consumed > 4 * NULLIF(c.previous_units, 0) THEN 95
            WHEN c.units_consumed > 3 * l.avg_monthly_units THEN 90
            WHEN c.units_consumed > 3 * NULLIF(c.previous_units, 0) THEN 85
            WHEN c.units_consumed < (0.3 * NULLIF(c.previous_units, 0)) THEN 80
            WHEN c.units_consumed > 2.5 * l.avg_monthly_units THEN 75
            WHEN c.units_consumed = c.previous_units THEN 70
            ELSE 20
        END) >= 40 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS risk_level

FROM consumption c
JOIN customers cu ON c.customer_id = cu.customer_id
JOIN locality_average l ON cu.city = l.city;


SELECT 
    'TOP_SUSPICIOUS_CUSTOMERS' AS report_type,
    customer_id,
    name,
    city,
    meter_type,
    AVG(fraud_score) AS avg_fraud_score,
    MAX(fraud_score) AS max_fraud_score,
    COUNT(*) AS total_readings,
    SUM(CASE WHEN risk_level IN ('HIGH', 'CRITICAL') THEN 1 ELSE 0 END) AS high_risk_months,
    ROUND((SUM(CASE WHEN risk_level IN ('HIGH', 'CRITICAL') THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS risk_percentage
FROM fraud_risk_dashboard
GROUP BY customer_id, name, city, meter_type
HAVING avg_fraud_score > 50
ORDER BY avg_fraud_score DESC, high_risk_months DESC
LIMIT 10;


SELECT 
    'SEASONAL_FRAUD_ANALYSIS' AS analysis_type,
    CASE 
        WHEN MONTH(reading_month) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(reading_month) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(reading_month) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Autumn'
    END AS season,
    
    COUNT(*) AS total_readings,
    AVG(fraud_score) AS avg_fraud_score,
    COUNT(CASE WHEN risk_level = 'CRITICAL' THEN 1 END) AS critical_cases,
    COUNT(CASE WHEN risk_level = 'HIGH' THEN 1 END) AS high_risk_cases,
    ROUND(AVG(units_consumed), 2) AS avg_consumption,
    
    -- Peak fraud months
    GROUP_CONCAT(DISTINCT 
        CASE WHEN fraud_score > 80 THEN MONTHNAME(reading_month) END 
        ORDER BY reading_month SEPARATOR ', '
    ) AS peak_fraud_months
    
FROM fraud_risk_dashboard
GROUP BY season
ORDER BY avg_fraud_score DESC;


SELECT 
    'MONTHLY_BILLING_REPORT' AS report_type,
    DATE_FORMAT(c.reading_month, '%Y-%m') AS billing_month,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(c.units_consumed) AS total_units_consumed,
    SUM(c.bill_amount) AS total_revenue,
    AVG(c.units_consumed) AS avg_consumption_per_customer,
    
    -- Fraud statistics
    COUNT(CASE WHEN frd.fraud_score >= 80 THEN 1 END) AS critical_fraud_cases,
    COUNT(CASE WHEN frd.fraud_score >= 60 THEN 1 END) AS total_suspicious_cases,
    ROUND(AVG(frd.fraud_score), 2) AS avg_fraud_score,
    
    -- Revenue impact
    SUM(CASE WHEN frd.fraud_score >= 60 THEN c.bill_amount ELSE 0 END) AS suspicious_revenue,
    ROUND((SUM(CASE WHEN frd.fraud_score >= 60 THEN c.bill_amount ELSE 0 END) / SUM(c.bill_amount)) * 100, 2) AS revenue_at_risk_percentage

FROM consumption c
JOIN fraud_risk_dashboard frd ON c.customer_id = frd.customer_id AND c.reading_month = frd.reading_month
GROUP BY DATE_FORMAT(c.reading_month, '%Y-%m')
ORDER BY billing_month DESC;


SELECT 
    'CITY_FRAUD_COMPARISON' AS analysis_type,
    cu.city,
    COUNT(DISTINCT cu.customer_id) AS total_customers,
    AVG(c.units_consumed) AS avg_consumption,
    l.avg_monthly_units AS city_baseline,
    
    -- Fraud metrics
    COUNT(CASE WHEN frd.fraud_score >= 80 THEN 1 END) AS critical_fraud_count,
    COUNT(CASE WHEN frd.fraud_score >= 60 THEN 1 END) AS total_fraud_count,
    ROUND(AVG(frd.fraud_score), 2) AS avg_fraud_score,
    ROUND((COUNT(CASE WHEN frd.fraud_score >= 60 THEN 1 END) / COUNT(*)) * 100, 2) AS fraud_rate_percentage,
    
    -- Ranking
    RANK() OVER (ORDER BY AVG(frd.fraud_score) DESC) AS fraud_risk_rank

FROM customers cu
JOIN consumption c ON cu.customer_id = c.customer_id
JOIN locality_average l ON cu.city = l.city
JOIN fraud_risk_dashboard frd ON cu.customer_id = frd.customer_id AND c.reading_month = frd.reading_month
GROUP BY cu.city, l.avg_monthly_units
ORDER BY avg_fraud_score DESC;


WITH expected_readings AS (
    SELECT 
        cu.customer_id,
        cu.name,
        DATE('2024-01-01') + INTERVAL (a.a + (10 * b.a)) MONTH AS expected_month
    FROM customers cu
    CROSS JOIN (SELECT 0 AS a UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a
    CROSS JOIN (SELECT 0 AS a UNION ALL SELECT 1) AS b
    WHERE DATE('2024-01-01') + INTERVAL (a.a + (10 * b.a)) MONTH <= '2024-12-01'
)
SELECT 
    'MISSING_READINGS_REPORT' AS analysis_type,
    er.customer_id,
    er.name,
    er.expected_month,
    CASE WHEN c.reading_month IS NULL THEN 'MISSING' ELSE 'PRESENT' END AS reading_status,
    
    -- Count missing readings per customer
    COUNT(*) OVER (PARTITION BY er.customer_id, CASE WHEN c.reading_month IS NULL THEN 1 ELSE 0 END) AS missing_count

FROM expected_readings er
LEFT JOIN consumption c ON er.customer_id = c.customer_id 
    AND DATE_FORMAT(er.expected_month, '%Y-%m-01') = DATE_FORMAT(c.reading_month, '%Y-%m-01')
WHERE c.reading_month IS NULL
ORDER BY er.customer_id, er.expected_month;


DELIMITER //
CREATE PROCEDURE FindFraudCustomers(
    IN fraud_threshold INT,
    IN analysis_period_months INT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_customer_id INT;
    DECLARE v_name VARCHAR(100);
    DECLARE v_avg_fraud_score DECIMAL(5,2);
    
    -- Cursor to iterate through high-risk customers
    DECLARE fraud_cursor CURSOR FOR
        SELECT 
            customer_id,
            name,
            AVG(fraud_score) as avg_score
        FROM fraud_risk_dashboard
        WHERE reading_month >= DATE_SUB(CURDATE(), INTERVAL analysis_period_months MONTH)
        GROUP BY customer_id, name
        HAVING AVG(fraud_score) >= fraud_threshold
        ORDER BY avg_score DESC;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Create temporary results table
    DROP TEMPORARY TABLE IF EXISTS temp_fraud_results;
    CREATE TEMPORARY TABLE temp_fraud_results (
        customer_id INT,
        customer_name VARCHAR(100),
        avg_fraud_score DECIMAL(5,2),
        risk_category VARCHAR(20)
    );
    
    OPEN fraud_cursor;
    
    read_loop: LOOP
        FETCH fraud_cursor INTO v_customer_id, v_name, v_avg_fraud_score;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Insert into results with risk categorization
        INSERT INTO temp_fraud_results VALUES (
            v_customer_id,
            v_name,
            v_avg_fraud_score,
            CASE 
                WHEN v_avg_fraud_score >= 90 THEN 'CRITICAL'
                WHEN v_avg_fraud_score >= 70 THEN 'HIGH'
                WHEN v_avg_fraud_score >= 50 THEN 'MEDIUM'
                ELSE 'LOW'
            END
        );
    END LOOP;
    
    CLOSE fraud_cursor;
    
    -- Return results
    SELECT 
        'DYNAMIC_FRAUD_DETECTION' AS report_type,
        customer_id,
        customer_name,
        avg_fraud_score,
        risk_category,
        CONCAT('Threshold: ', fraud_threshold, ', Period: ', analysis_period_months, ' months') AS analysis_params
    FROM temp_fraud_results
    ORDER BY avg_fraud_score DESC;
    
    -- Also insert high-risk cases into fraud_flags table
    INSERT INTO fraud_flags (customer_id, reason, month, severity, anomaly_score, detected_by)
    SELECT 
        customer_id,
        CONCAT('Dynamic detection - Avg score: ', avg_fraud_score),
        CURDATE(),
        CASE 
            WHEN risk_category = 'CRITICAL' THEN 'critical'
            WHEN risk_category = 'HIGH' THEN 'high'
            ELSE 'medium'
        END,
        avg_fraud_score,
        'stored_procedure'
    FROM temp_fraud_results
    WHERE avg_fraud_score >= 70;
    
END//
DELIMITER ;


SELECT 
    'CUSTOMER_SEGMENTATION' AS analysis_type,
    customer_id,
    name,
    city,
    meter_type,
    avg_monthly_consumption,
    avg_fraud_score,
    
    -- Customer segments based on consumption and fraud risk
    CASE 
        WHEN avg_monthly_consumption > 800 AND avg_fraud_score > 70 THEN 'High Consumer - High Risk'
        WHEN avg_monthly_consumption > 800 AND avg_fraud_score <= 70 THEN 'High Consumer - Low Risk'
        WHEN avg_monthly_consumption BETWEEN 400 AND 800 AND avg_fraud_score > 70 THEN 'Medium Consumer - High Risk'
        WHEN avg_monthly_consumption BETWEEN 400 AND 800 AND avg_fraud_score <= 70 THEN 'Medium Consumer - Low Risk'
        WHEN avg_monthly_consumption < 400 AND avg_fraud_score > 70 THEN 'Low Consumer - High Risk'
        ELSE 'Low Consumer - Low Risk'
    END AS customer_segment,
    
    -- Action recommendations
    CASE 
        WHEN avg_fraud_score >= 80 THEN 'Immediate Investigation Required'
        WHEN avg_fraud_score >= 60 THEN 'Enhanced Monitoring'
        WHEN avg_fraud_score >= 40 THEN 'Periodic Review'
        ELSE 'Standard Monitoring'
    END AS recommended_action

FROM (
    SELECT 
        customer_id,
        name,
        city,
        meter_type,
        ROUND(AVG(units_consumed), 2) AS avg_monthly_consumption,
        ROUND(AVG(fraud_score), 2) AS avg_fraud_score
    FROM fraud_risk_dashboard
    GROUP BY customer_id, name, city, meter_type
) AS customer_summary
ORDER BY avg_fraud_score DESC, avg_monthly_consumption DESC;


SELECT 
    'COMPREHENSIVE_FRAUD_SUMMARY' AS report_type,
    
    -- Overall statistics
    COUNT(DISTINCT customer_id) AS total_customers_analyzed,
    COUNT(*) AS total_readings_analyzed,
    ROUND(AVG(fraud_score), 2) AS overall_avg_fraud_score,
    
    -- Risk distribution
    COUNT(CASE WHEN risk_level = 'CRITICAL' THEN 1 END) AS critical_risk_readings,
    COUNT(CASE WHEN risk_level = 'HIGH' THEN 1 END) AS high_risk_readings,
    COUNT(CASE WHEN risk_level = 'MEDIUM' THEN 1 END) AS medium_risk_readings,
    COUNT(CASE WHEN risk_level = 'LOW' THEN 1 END) AS low_risk_readings,
    
    -- Percentages
    ROUND((COUNT(CASE WHEN risk_level = 'CRITICAL' THEN 1 END) / COUNT(*)) * 100, 2) AS critical_risk_percentage,
    ROUND((COUNT(CASE WHEN risk_level IN ('HIGH', 'CRITICAL') THEN 1 END) / COUNT(*)) * 100, 2) AS high_risk_percentage,
    
    -- Financial impact estimates
    SUM(units_consumed) AS total_units_analyzed,
    ROUND(AVG(units_consumed), 2) AS avg_consumption_per_reading,
    
    -- Top fraud indicators
    COUNT(CASE WHEN fraud_score = 100 THEN 1 END) AS negative_consumption_cases,
    COUNT(CASE WHEN fraud_score >= 95 THEN 1 END) AS extreme_spike_cases,
    COUNT(CASE WHEN fraud_score = 70 THEN 1 END) AS constant_usage_cases

FROM fraud_risk_dashboard;

-- Show created objects
SHOW TABLES;
SELECT 'Views created:' AS info;
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SELECT 'Procedures created:' AS info;
SHOW PROCEDURE STATUS WHERE Db = 'electricity_fraud_db';