const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');

const app = express();

app.use(cors({
    origin: 'http://localhost:3000',
    credentials: true
}));

app.use(express.json());

const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'electricity_fraud_db'
};

async function testConnection() {
    try {
        const connection = await mysql.createConnection(dbConfig);
        console.log('✅ Connected to MySQL database: electricity_fraud_db');
        await connection.end();
    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
    }
}

// API: Dashboard Metrics (REAL DATA)
app.get('/api/dashboard', async (req, res) => {
    try {
        const connection = await mysql.createConnection(dbConfig);
        
        // Get total customers
        const [totalResult] = await connection.execute('SELECT COUNT(*) as total FROM customers');
        const totalCustomers = totalResult[0].total;
        
        // Get critical fraud cases
        const [criticalResult] = await connection.execute(
            'SELECT COUNT(*) as count FROM fraud_risk_dashboard WHERE risk_level = ?', 
            ['CRITICAL']
        );
        const criticalCases = criticalResult[0].count;
        
        // Get high risk cases
        const [highResult] = await connection.execute(
            'SELECT COUNT(*) as count FROM fraud_risk_dashboard WHERE risk_level = ?', 
            ['HIGH']
        );
        const highRiskCases = highResult[0].count;
        
        // Get average fraud score
        const [avgResult] = await connection.execute('SELECT AVG(fraud_score) as avg_score FROM fraud_risk_dashboard');
        const avgFraudScore = avgResult[0].avg_score ? Math.round(avgResult[0].avg_score * 100) / 100 : 0;
        
        // Calculate detection rate
        const detectionRate = totalCustomers > 0 ? Math.round(((criticalCases + highRiskCases) / totalCustomers) * 100 * 100) / 100 : 0;
        
        await connection.end();
        
        res.json({
            success: true,
            data: {
                totalCustomers: totalCustomers,
                criticalCases: criticalCases,
                highRiskCases: highRiskCases,
                avgFraudScore: avgFraudScore,
                detectionRate: detectionRate + '%'
            }
        });
        
    } catch (error) {
        console.error('Dashboard API error:', error);
        res.json({
            success: false,
            error: error.message
        });
    }
});

// API: Critical Cases (FIXED - using existing columns only)
app.get('/api/critical-cases', async (req, res) => {
    try {
        const connection = await mysql.createConnection(dbConfig);
        
        const [results] = await connection.execute(`
            SELECT 
                frd.customer_id,
                frd.name,
                frd.city,
                frd.fraud_score,
                frd.risk_level,
                frd.reading_month as last_reading_date,
                frd.units_consumed,
                frd.meter_type,
                CASE 
                    WHEN frd.fraud_score >= 95 THEN 'Consumption spike, Meter tampering'
                    WHEN frd.fraud_score >= 85 THEN 'Usage pattern anomaly'
                    WHEN frd.fraud_score >= 75 THEN 'Consumption irregularity'
                    ELSE 'Minor deviation detected'
                END as anomaly_types
            FROM fraud_risk_dashboard frd
            WHERE frd.risk_level IN ('CRITICAL', 'HIGH')
            ORDER BY frd.fraud_score DESC
            LIMIT 20
        `);
        
        await connection.end();
        
        res.json({
            success: true,
            data: results
        });
        
    } catch (error) {
        console.error('Critical cases API error:', error);
        res.json({
            success: false,
            error: error.message
        });
    }
});

// API: Add Reading (FIXED - using new electricity_consumption table)
app.post('/api/add-reading', async (req, res) => {
    try {
        const { customerId, consumption, readingDate } = req.body;
        const connection = await mysql.createConnection(dbConfig);
        
        // Check if customer exists
        const [customerCheck] = await connection.execute('SELECT customer_id FROM customers WHERE customer_id = ?', [customerId]);
        
        if (customerCheck.length === 0) {
            await connection.end();
            return res.json({
                success: false,
                error: `Customer ID ${customerId} not found. Available customers: 1-20`
            });
        }
        
        // Insert into electricity_consumption table
        await connection.execute(
            'INSERT INTO electricity_consumption (customer_id, consumption_kwh, reading_date, meter_reading) VALUES (?, ?, ?, ?)',
            [customerId, consumption, readingDate, Math.floor(Math.random() * 90000) + 10000]
        );
        
        // Also add to main consumption table for fraud analysis
        const [lastReading] = await connection.execute(
            'SELECT units_consumed FROM consumption WHERE customer_id = ? ORDER BY reading_month DESC LIMIT 1',
            [customerId]
        );
        
        const previousUnits = lastReading.length > 0 ? lastReading[0].units_consumed : 0;
        
        await connection.execute(
            'INSERT INTO consumption (customer_id, reading_month, units_consumed, previous_units, bill_amount) VALUES (?, ?, ?, ?, ?)',
            [customerId, readingDate, consumption, previousUnits, consumption * 6]
        );
        
        await connection.end();
        
        res.json({
            success: true,
            message: 'Reading added successfully! Fraud analysis updated.'
        });
        
    } catch (error) {
        console.error('Add reading API error:', error);
        res.json({
            success: false,
            error: error.message
        });
    }
});

// API: Get Recent Readings
app.get('/api/recent-readings', async (req, res) => {
    try {
        const connection = await mysql.createConnection(dbConfig);
        
        const [results] = await connection.execute(`
            SELECT 
                ec.consumption_id,
                ec.customer_id,
                c.name,
                ec.consumption_kwh,
                ec.reading_date,
                ec.meter_reading,
                ec.created_at
            FROM electricity_consumption ec
            JOIN customers c ON ec.customer_id = c.customer_id
            ORDER BY ec.created_at DESC
            LIMIT 10
        `);
        
        await connection.end();
        
        res.json({
            success: true,
            data: results
        });
        
    } catch (error) {
        console.error('Recent readings API error:', error);
        res.json({
            success: false,
            error: error.message
        });
    }
});

const PORT = 8080;
app.listen(PORT, async () => {
    console.log(`🚀 Node.js Backend running on http://localhost:${PORT}`);
    console.log('📊 Dashboard API: http://localhost:8080/api/dashboard');
    console.log('🚨 Critical cases: http://localhost:8080/api/critical-cases');
    console.log('📈 Recent readings: http://localhost:8080/api/recent-readings');
    console.log('✨ Using REAL fraud_risk_dashboard view data!');
    
    await testConnection();
});
