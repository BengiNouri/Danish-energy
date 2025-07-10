"""
Simplified Dashboard Data Service
Provides mock data for Danish Energy Analytics dashboards
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import json
from datetime import datetime, timedelta
import random

app = Flask(__name__)
CORS(app)

# Mock data generators
def generate_mock_kpis():
    return {
        'total_days': 30,
        'avg_co2_intensity': 118.5,
        'avg_renewable_percentage': 67.8,
        'avg_electricity_price': 83.2,
        'total_energy_production': 2450000,
        'total_energy_consumption': 2380000
    }

def generate_mock_renewable_trends(days=30):
    data = []
    base_date = datetime.now() - timedelta(days=days)
    
    for i in range(days):
        date = base_date + timedelta(days=i)
        for area in ['DK1', 'DK2']:
            renewable_base = 65 if area == 'DK1' else 70
            data.append({
                'date_actual': date.strftime('%Y-%m-%d'),
                'price_area_code': area,
                'renewable_percentage': renewable_base + random.uniform(-15, 15),
                'wind_percentage': 45 + random.uniform(-10, 10),
                'solar_percentage': 8 + random.uniform(-3, 5),
                'total_renewable_mwh': 1200 + random.uniform(-300, 300),
                'total_production_mwh': 1800 + random.uniform(-200, 200)
            })
    return data

def generate_mock_co2_analysis(days=30):
    data = []
    base_date = datetime.now() - timedelta(days=days)
    
    for i in range(days):
        date = base_date + timedelta(days=i)
        for area in ['DK1', 'DK2']:
            co2_base = 115 if area == 'DK1' else 125
            data.append({
                'date_actual': date.strftime('%Y-%m-%d'),
                'price_area_code': area,
                'avg_co2_intensity': co2_base + random.uniform(-20, 30),
                'min_co2_intensity': co2_base - 30 + random.uniform(-10, 10),
                'max_co2_intensity': co2_base + 50 + random.uniform(-10, 20),
                'peak_co2_intensity': co2_base + 15 + random.uniform(-10, 15),
                'offpeak_co2_intensity': co2_base - 10 + random.uniform(-10, 10),
                'data_points': 288
            })
    return data

def generate_mock_price_analysis(days=30):
    data = []
    base_date = datetime.now() - timedelta(days=days)
    
    for i in range(days):
        date = base_date + timedelta(days=i)
        for area in ['DK1', 'DK2']:
            price_base = 80 if area == 'DK1' else 85
            data.append({
                'date_actual': date.strftime('%Y-%m-%d'),
                'price_area_code': area,
                'avg_price_eur': price_base + random.uniform(-30, 40),
                'min_price_eur': price_base - 40 + random.uniform(-20, 10),
                'max_price_eur': price_base + 60 + random.uniform(-10, 30),
                'price_volatility': 15 + random.uniform(0, 25),
                'negative_price_hours': random.randint(0, 3),
                'price_spike_hours': random.randint(0, 5),
                'peak_price_eur': price_base + 20 + random.uniform(-10, 20),
                'offpeak_price_eur': price_base - 15 + random.uniform(-10, 10)
            })
    return data

def generate_mock_hourly_patterns():
    data = []
    for hour in range(24):
        for area in ['DK1', 'DK2']:
            # Simulate daily patterns
            renewable_factor = 1.2 if 10 <= hour <= 16 else 0.8  # Higher during day
            co2_factor = 0.8 if 10 <= hour <= 16 else 1.2  # Lower during day
            price_factor = 1.3 if hour in [8, 9, 17, 18, 19, 20] else 0.9  # Peak hours
            
            data.append({
                'hour': hour,
                'price_area_code': area,
                'avg_co2_intensity': (120 + random.uniform(-10, 10)) * co2_factor,
                'avg_renewable_percentage': (65 + random.uniform(-5, 5)) * renewable_factor,
                'avg_price_eur': (80 + random.uniform(-10, 10)) * price_factor,
                'total_production_mwh': 150 + random.uniform(-20, 20),
                'total_consumption_mwh': 140 + random.uniform(-15, 15),
                'data_points': 7
            })
    return data

def generate_mock_energy_mix(days=30):
    data = []
    base_date = datetime.now() - timedelta(days=days)
    
    for i in range(days):
        date = base_date + timedelta(days=i)
        for area in ['DK1', 'DK2']:
            data.append({
                'date_actual': date.strftime('%Y-%m-%d'),
                'price_area_code': area,
                'offshore_wind_mwh': 400 + random.uniform(-100, 150),
                'onshore_wind_mwh': 300 + random.uniform(-80, 120),
                'solar_mwh': 80 + random.uniform(-20, 40),
                'hydro_mwh': 20 + random.uniform(-5, 10),
                'conventional_mwh': 600 + random.uniform(-150, 100),
                'total_production_mwh': 1400 + random.uniform(-200, 200)
            })
    return data

# API Routes
@app.route('/api/kpis')
def get_kpis():
    return jsonify(generate_mock_kpis())

@app.route('/api/renewable-trends')
def get_renewable_trends():
    days = request.args.get('days', 30, type=int)
    return jsonify(generate_mock_renewable_trends(days))

@app.route('/api/co2-analysis')
def get_co2_analysis():
    days = request.args.get('days', 30, type=int)
    return jsonify(generate_mock_co2_analysis(days))

@app.route('/api/price-analysis')
def get_price_analysis():
    days = request.args.get('days', 30, type=int)
    return jsonify(generate_mock_price_analysis(days))

@app.route('/api/hourly-patterns')
def get_hourly_patterns():
    return jsonify(generate_mock_hourly_patterns())

@app.route('/api/energy-mix')
def get_energy_mix():
    days = request.args.get('days', 30, type=int)
    return jsonify(generate_mock_energy_mix(days))

@app.route('/api/health')
def health_check():
    return jsonify({
        'status': 'healthy', 
        'timestamp': datetime.now().isoformat(),
        'message': 'Danish Energy Analytics API is running with mock data'
    })

if __name__ == '__main__':
    print("Starting Danish Energy Analytics Dashboard API with mock data...")
    app.run(host='0.0.0.0', port=5000, debug=False)

