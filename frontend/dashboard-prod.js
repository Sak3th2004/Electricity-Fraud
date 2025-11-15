const API_BASE = 'http://128.199.17.121:8080/api';

let retryCount = 0;
const MAX_RETRIES = 3;

document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 Fraud Detection Dashboard Loading...');
    loadDashboard();
    setupForm();
    setRandomDate();
});

async function loadDashboard() {
    try {
        console.log('📊 Loading dashboard data...');
        await Promise.all([
            loadDashboardMetrics(),
            loadCriticalCases()
        ]);
        console.log('✅ Dashboard loaded successfully!');
    } catch (error) {
        console.error('❌ Dashboard loading failed:', error);
        if (retryCount < MAX_RETRIES) {
            retryCount++;
            console.log(`🔄 Retrying... (${retryCount}/${MAX_RETRIES})`);
            setTimeout(loadDashboard, 2000);
        }
    }
}

async function loadDashboardMetrics() {
    try {
        const response = await fetch(`${API_BASE}/dashboard`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        
        const result = await response.json();
        if (result.success) {
            updateMetricsDisplay(result.data);
            updateChart(result.data);
        } else {
            throw new Error(result.error);
        }
    } catch (error) {
        console.error('❌ Metrics error:', error);
        showErrorMetrics();
    }
}

async function loadCriticalCases() {
    try {
        const response = await fetch(`${API_BASE}/critical-cases`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        
        const result = await response.json();
        if (result.success) {
            displayCriticalCases(result.data);
        } else {
            throw new Error(result.error);
        }
    } catch (error) {
        console.error('❌ Critical cases error:', error);
        document.querySelector('#criticalTable tbody').innerHTML = 
            '<tr><td colspan="6" class="error">Failed to load critical cases</td></tr>';
    }
}

function updateMetricsDisplay(data) {
    animateNumber('totalCustomers', data.totalCustomers);
    animateNumber('criticalCases', data.criticalCases);
    animateNumber('avgFraudScore', data.avgFraudScore);
    document.getElementById('detectionRate').textContent = data.detectionRate;
}

function animateNumber(elementId, targetValue) {
    const element = document.getElementById(elementId);
    const startValue = 0;
    const duration = 1000;
    const startTime = performance.now();
    
    function updateNumber(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const currentValue = Math.floor(startValue + (targetValue - startValue) * progress);
        
        element.textContent = currentValue;
        
        if (progress < 1) {
            requestAnimationFrame(updateNumber);
        } else {
            element.textContent = targetValue;
        }
    }
    
    requestAnimationFrame(updateNumber);
}

async function updateChart(dashboardData) {
    try {
        const response = await fetch(`${API_BASE}/critical-cases`);
        const result = await response.json();
        
        if (result.success) {
            const cases = result.data;
            const critical = cases.filter(c => (c.risk_level || '').toUpperCase() === 'CRITICAL').length;
            const high = cases.filter(c => (c.risk_level || '').toUpperCase() === 'HIGH').length;
            const otherCases = cases.filter(c => !['CRITICAL', 'HIGH'].includes((c.risk_level || '').toUpperCase()));
            const medium = otherCases.filter(c => c.fraud_score >= 60 && c.fraud_score < 75).length;
            const total = dashboardData.totalCustomers;
            const accountedFor = critical + high + medium;
            const low = Math.max(0, total - accountedFor);
            
            updateChartBars(critical, high, medium, low, total);
        }
    } catch (error) {
        console.error('❌ Chart update error:', error);
        updateChartBars(2, 3, 5, 10, 20);
    }
}

function updateChartBars(critical, high, medium, low, total) {
    const maxForPercent = total > 0 ? total : 20;
    
    const criticalPercent = (critical / maxForPercent) * 100;
    const highPercent = (high / maxForPercent) * 100;
    const mediumPercent = (medium / maxForPercent) * 100;
    const lowPercent = (low / maxForPercent) * 100;
    
    setTimeout(() => {
        const criticalBar = document.getElementById('criticalBar');
        const criticalValue = document.getElementById('criticalValue');
        if (criticalBar && criticalValue) {
            criticalBar.style.width = Math.max(criticalPercent, 2) + '%';
            criticalValue.textContent = critical;
        }
    }, 200);
    
    setTimeout(() => {
        const highBar = document.getElementById('highBar');
        const highValue = document.getElementById('highValue');
        if (highBar && highValue) {
            highBar.style.width = Math.max(highPercent, 2) + '%';
            highValue.textContent = high;
        }
    }, 400);
    
    setTimeout(() => {
        const mediumBar = document.getElementById('mediumBar');
        const mediumValue = document.getElementById('mediumValue');
        if (mediumBar && mediumValue) {
            mediumBar.style.width = Math.max(mediumPercent, 2) + '%';
            mediumValue.textContent = medium;
        }
    }, 600);
    
    setTimeout(() => {
        const lowBar = document.getElementById('lowBar');
        const lowValue = document.getElementById('lowValue');
        if (lowBar && lowValue) {
            lowBar.style.width = Math.max(lowPercent, 10) + '%';
            lowValue.textContent = low;
        }
    }, 800);
}

function displayCriticalCases(cases) {
    const tbody = document.querySelector('#criticalTable tbody');
    tbody.innerHTML = '';
    
    if (cases.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="loading">No critical cases found</td></tr>';
        return;
    }
    
    cases.forEach((case_, index) => {
        const row = document.createElement('tr');
        const riskClass = (case_.risk_level || 'low').toLowerCase();
        
        row.innerHTML = `
            <td><strong>${case_.customer_id}</strong></td>
            <td><i class="fas fa-user"></i> ${case_.name || 'N/A'}</td>
            <td><i class="fas fa-map-marker-alt"></i> ${case_.city || 'N/A'}</td>
            <td><strong style="color: ${case_.fraud_score >= 80 ? '#dc3545' : '#ffc107'}">${case_.fraud_score}</strong></td>
            <td><span class="risk-${riskClass}">${case_.risk_level || 'LOW'}</span></td>
            <td>${case_.last_reading_date || case_.reading_month || 'N/A'}</td>
        `;
        
        row.style.opacity = '0';
        row.style.transform = 'translateY(20px)';
        tbody.appendChild(row);
        
        setTimeout(() => {
            row.style.transition = 'all 0.3s ease';
            row.style.opacity = '1';
            row.style.transform = 'translateY(0)';
        }, index * 100);
    });
}

function setupForm() {
    document.getElementById('addReadingForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = {
            customerId: parseInt(document.getElementById('customerId').value),
            consumption: parseFloat(document.getElementById('consumption').value),
            readingDate: document.getElementById('readingDate').value
        };
        
        try {
            await addNewReading(formData);
        } catch (error) {
            console.error('❌ Add reading error:', error);
            if (error.message.includes('Duplicate entry')) {
                alert('This customer already has a reading for this date. Try a different date or customer.');
                setRandomDate();
            } else {
                alert('Error: ' + error.message);
            }
        }
    });
}

async function addNewReading(data) {
    const button = document.querySelector('.btn-primary');
    const originalText = button.innerHTML;
    
    try {
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Adding...';
        button.disabled = true;
        
        const response = await fetch(`${API_BASE}/add-reading`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        
        const result = await response.json();
        
        if (result.success) {
            button.innerHTML = '<i class="fas fa-check"></i> Added Successfully!';
            button.style.background = '#28a745';
            
            document.getElementById('consumption').value = '';
            setRandomDate();
            
            setTimeout(() => {
                loadDashboard();
                button.innerHTML = originalText;
                button.style.background = '';
                button.disabled = false;
            }, 1500);
        } else {
            throw new Error(result.error || 'Failed to add reading');
        }
    } catch (error) {
        button.innerHTML = '<i class="fas fa-times"></i> Error!';
        button.style.background = '#dc3545';
        
        setTimeout(() => {
            button.innerHTML = originalText;
            button.style.background = '';
            button.disabled = false;
        }, 3000);
        
        throw error;
    }
}

function showErrorMetrics() {
    ['totalCustomers', 'criticalCases', 'avgFraudScore', 'detectionRate'].forEach(id => {
        document.getElementById(id).textContent = 'Error';
    });
}

function setRandomDate() {
    const dateInput = document.getElementById('readingDate');
    if (dateInput) {
        const start = new Date('2024-12-01');
        const end = new Date('2025-12-31');
        const randomTime = start.getTime() + Math.random() * (end.getTime() - start.getTime());
        const randomDate = new Date(randomTime);
        
        dateInput.value = randomDate.toISOString().split('T')[0];
    }
}

window.fillNormalCase = function() {
    document.getElementById('customerId').value = 5;
    document.getElementById('consumption').value = 150;
    setRandomDate();
};

window.fillSuspiciousCase = function() {
    document.getElementById('customerId').value = 3;
    document.getElementById('consumption').value = 1200;
    setRandomDate();
};

window.fillCriticalCase = function() {
    document.getElementById('customerId').value = 7;
    document.getElementById('consumption').value = -50;
    setRandomDate();
};

window.fillHighCase = function() {
    document.getElementById('customerId').value = 8;
    document.getElementById('consumption').value = 800;
    setRandomDate();
};

function addQuickTestButtons() {
    const formContainer = document.querySelector('.form-container');
    
    const testButtonsHTML = `
        <div style="margin-top: 1rem; padding: 1rem; background: #f8f9fa; border-radius: 8px;">
            <h4 style="margin-bottom: 1rem; color: #333;">
                <i class="fas fa-vial"></i> Quick Test Cases
            </h4>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem;">
                <button type="button" onclick="fillNormalCase()" style="padding: 0.5rem; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer;">
                    Normal (150 kWh)
                </button>
                <button type="button" onclick="fillSuspiciousCase()" style="padding: 0.5rem; background: #ffc107; color: black; border: none; border-radius: 4px; cursor: pointer;">
                    Suspicious (1200 kWh)
                </button>
                <button type="button" onclick="fillCriticalCase()" style="padding: 0.5rem; background: #dc3545; color: white; border: none; border-radius: 4px; cursor: pointer;">
                    Critical (-50 kWh)
                </button>
                <button type="button" onclick="fillHighCase()" style="padding: 0.5rem; background: #fd7e14; color: white; border: none; border-radius: 4px; cursor: pointer;">
                    High (800 kWh)
                </button>
            </div>
        </div>
    `;
    
    formContainer.insertAdjacentHTML('beforeend', testButtonsHTML);
}

document.addEventListener('DOMContentLoaded', () => {
    setTimeout(addQuickTestButtons, 1000);
});

console.log('🚀 Dashboard script loaded!');
console.log('📡 API Base:', API_BASE);
