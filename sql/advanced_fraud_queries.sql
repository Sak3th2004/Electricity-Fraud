

USE electricity_fraud_db;


SELECT 
    'SPIKE DETECTION' AS analysis_type,
    c.customer_id,
    cu.name,
    cu.city,
    c.reading_month,
    c.units_consumed,
    c.previous_units,
    ROUND((c.units_consumed / NULLIF(c.previous_units, 0)), 2) AS spike_ratio,
    CASE 
        WHEN c.units_consumed > 4 * c.previous_units THEN 'CRITICAL'
        WHEN c.units_consumed > 3 * c.previous_units THEN 'HIGH'
        WHEN c.units_consumed > 2.5 * c.previous_units THEN 'MEDIUM'
        ELSE 'NORMAL'
    END AS risk_level
FROM consumption c
JOIN customers cu ON c.customer_id = cu.customer_id
WHERE (c.units_consumed > 2.5 * c.previous_units) AND c.previous_units > 0
ORDER BY spike_ratio DESC;


SELECT
    customer_id,
    reading_month,
    units_consumed,
    
    -- Moving Average using Window Function
    ROUND(AVG(units_consumed) OVER (
        PARTITION BY customer_id
        ORDER BY reading_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3month,
    
    -- LAG function to get previous month
    LAG(units_consumed, 1) OVER (
        PARTITION BY customer_id 
        ORDER BY reading_month
    ) AS prev_month_usage,
    
    -- LEAD function to get next month
    LEAD(units_consumed, 1) OVER (
        PARTITION BY customer_id 
        ORDER BY reading_month
    ) AS next_month_usage,
    
    -- Deviation from moving average
    ROUND(units_consumed - AVG(units_consumed) OVER (
        PARTITION BY customer_id
        ORDER BY reading_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS deviation_from_avg
    
FROM consumption
WHERE customer_id IN (1, 11, 16, 20) -- Focus on specific customers
ORDER BY customer_id, reading_month;


SELECT 
    'METER TAMPERING' AS fraud_type,
    c.customer_id,
    cu.name,
    cu.city,
    c.reading_month,
    c.units_consumed,
    c.previous_units,
    
    
    ROUND(((c.previous_units - c.units_consumed) / NULLIF(c.previous_units, 0)) * 100, 2) AS drop_percentage,
    
    CASE 
        WHEN c.units_consumed < 0 THEN 'NEGATIVE_READING'
        WHEN c.units_consumed < (0.3 * c.previous_units) THEN 'MAJOR_DROP'
        WHEN c.units_consumed < (0.5 * c.previous_units) THEN 'SUSPICIOUS_DROP'
        ELSE 'NORMAL'
    END AS tampering_type
    
FROM consumption c
JOIN customers cu ON c.customer_id = cu.customer_id
WHERE c.units_consumed < 0 
   OR (c.units_consumed < (0.5 * c.previous_units) AND c.previous_units > 0)
ORDER BY c.units_consumed ASC;


SELECT 
    'LOCALITY_ANOMALY' AS analysis_type,
    cu.customer_id,
    cu.name,
    cu.city,
    cu.meter_type,
    c.reading_month,
    c.units_consumed,
    l.avg_monthly_units AS city_average,
    
    -- Calculate ratio vs city average
    ROUND((c.units_consumed / l.avg_monthly_units), 2) AS vs_city_ratio,
    
    -- Seasonal adjustment
    CASE 
        WHEN MONTH(c.reading_month) IN (5,6,7,8) THEN l.peak_season_units
        ELSE l.off_peak_units
    END AS seasonal_baseline,
    
    -- Advanced scoring
    CASE 
        WHEN c.units_consumed > (3 * l.avg_monthly_units) THEN 'EXTREME_OUTLIER'
        WHEN c.units_consumed > (2.5 * l.avg_monthly_units) THEN 'HIGH_ANOMALY'
        WHEN c.units_consumed > (2 * l.avg_monthly_units) THEN 'MODERATE_ANOMALY'
        ELSE 'NORMAL'
    END AS anomaly_level
    
FROM consumption c
JOIN customers cu ON cu.customer_id = c.customer_id
JOIN locality_average l ON cu.city = l.city
WHERE c.units_consumed > (2 * l.avg_monthly_units)
ORDER BY vs_city_ratio DESC;


WITH constant_usage_analysis AS (
    SELECT 
        customer_id,
        COUNT(*) AS total_readings,
        COUNT(DISTINCT units_consumed) AS unique_consumption_values,
        AVG(units_consumed) AS avg_consumption,
        STDDEV(units_consumed) AS consumption_stddev
    FROM consumption
    GROUP BY customer_id
)
SELECT 
    'CONSTANT_USAGE_FRAUD' AS fraud_type,
    cua.customer_id,
    cu.name,
    cu.city,
    cu.meter_type,
    cua.total_readings,
    cua.unique_consumption_values,
    ROUND(cua.avg_consumption, 2) AS avg_monthly_usage,
    ROUND(COALESCE(cua.consumption_stddev, 0), 2) AS usage_variation,
    
    CASE 
        WHEN cua.unique_consumption_values = 1 THEN 'IDENTICAL_EVERY_MONTH'
        WHEN cua.unique_consumption_values <= 2 THEN 'MINIMAL_VARIATION'
        WHEN cua.consumption_stddev < 10 THEN 'VERY_LOW_VARIATION'
        ELSE 'NORMAL_VARIATION'
    END AS suspicion_level
    
FROM constant_usage_analysis cua
JOIN customers cu ON cu.customer_id = cua.customer_id
WHERE cua.unique_consumption_values <= 3 OR cua.consumption_stddev < 20
ORDER BY cua.unique_consumption_values ASC, cua.consumption_stddev ASC;


SELECT
    'FRAUD_RISK_SCORING' AS analysis_type,
    c.customer_id,
    cu.name,
    cu.city,
    cu.meter_type,
    c.reading_month,
    c.units_consumed,
    c.previous_units,
    l.avg_monthly_units,
    
    
    (CASE 
        -- Critical fraud indicators
        WHEN c.units_consumed < 0 THEN 100
        WHEN c.units_consumed > 4 * NULLIF(c.previous_units, 0) THEN 95
        WHEN c.units_consumed > 3 * l.avg_monthly_units THEN 90
        
        -- High risk indicators
        WHEN c.units_consumed > 3 * NULLIF(c.previous_units, 0) THEN 85
        WHEN c.units_consumed < (0.3 * NULLIF(c.previous_units, 0)) THEN 80
        WHEN c.units_consumed > 2.5 * l.avg_monthly_units THEN 75
        
        -- Medium risk indicators
        WHEN c.units_consumed = c.previous_units THEN 70
        WHEN c.units_consumed > 2 * l.avg_monthly_units THEN 65
        WHEN c.units_consumed > 2 * NULLIF(c.previous_units, 0) THEN 60
        
        -- Low risk
        WHEN c.units_consumed > 1.5 * l.avg_monthly_units THEN 40
        WHEN c.units_consumed < (0.8 * l.avg_monthly_units) THEN 30
        
        -- Normal usage
        ELSE 15
    END) AS fraud_risk_score,
    
    -- Risk categorization
    CASE 
        WHEN (CASE 
            WHEN c.units_consumed < 0 THEN 100
            WHEN c.units_consumed > 4 * NULLIF(c.previous_units, 0) THEN 95
            WHEN c.units_consumed > 3 * l.avg_monthly_units THEN 90
            WHEN c.units_consumed > 3 * NULLIF(c.previous_units, 0) THEN 85
            WHEN c.units_consumed < (0.3 * NULLIF(c.previous_units, 0)) THEN 80
            WHEN c.units_consumed > 2.5 * l.avg_monthly_units THEN 75
            WHEN c.units_consumed = c.previous_units THEN 70
            WHEN c.units_consumed > 2 * l.avg_monthly_units THEN 65
            WHEN c.units_consumed > 2 * NULLIF(c.previous_units, 0) THEN 60
            WHEN c.units_consumed > 1.5 * l.avg_monthly_units THEN 40
            WHEN c.units_consumed < (0.8 * l.avg_monthly_units) THEN 30
            ELSE 15
        END) >= 80 THEN ' CRITICAL'
        WHEN (CASE 
            WHEN c.units_consumed < 0 THEN 100
            WHEN c.units_consumed > 4 * NULLIF(c.previous_units, 0) THEN 95
            WHEN c.units_consumed > 3 * l.avg_monthly_units THEN 90
            WHEN c.units_consumed > 3 * NULLIF(c.previous_units, 0) THEN 85
            WHEN c.units_consumed < (0.3 * NULLIF(c.previous_units, 0)) THEN 80
            WHEN c.units_consumed > 2.5 * l.avg_monthly_units THEN 75
            WHEN c.units_consumed = c.previous_units THEN 70
            WHEN c.units_consumed > 2 * l.avg_monthly_units THEN 65
            WHEN c.units_consumed > 2 * NULLIF(c.previous_units, 0) THEN 60
            WHEN c.units_consumed > 1.5 * l.avg_monthly_units THEN 40
            WHEN c.units_consumed < (0.8 * l.avg_monthly_units) THEN 30
            ELSE 15
        END) >= 60 THEN ' HIGH'
        WHEN (CASE 
            WHEN c.units_consumed < 0 THEN 100
            WHEN c.units_consumed > 4 * NULLIF(c.previous_units, 0) THEN 95
            WHEN c.units_consumed > 3 * l.avg_monthly_units THEN 90
            WHEN c.units_consumed > 3 * NULLIF(c.previous_units, 0) THEN 85
            WHEN c.units_consumed < (0.3 * NULLIF(c.previous_units, 0)) THEN 80
            WHEN c.units_consumed > 2.5 * l.avg_monthly_units THEN 75
            WHEN c.units_consumed = c.previous_units THEN 70
            WHEN c.units_consumed > 2 * l.avg_monthly_units THEN 65
            WHEN c.units_consumed > 2 * NULLIF(c.previous_units, 0) THEN 60
            WHEN c.units_consumed > 1.5 * l.avg_monthly_units THEN 40
            WHEN c.units_consumed < (0.8 * l.avg_monthly_units) THEN 30
            ELSE 15
        END) >= 40 THEN ' MEDIUM'
        ELSE ' LOW'
    END AS risk_category

FROM consumption c
JOIN customers cu ON c.customer_id = cu.customer_id
JOIN locality_average l ON cu.city = l.city
ORDER BY fraud_risk_score DESC;