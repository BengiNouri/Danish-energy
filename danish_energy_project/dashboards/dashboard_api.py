"""
Dashboard Data Service
Provides data access layer for Danish Energy Analytics dashboards
Connects to PostgreSQL data warehouse and serves data via REST API
"""

import pandas as pd
import psycopg2
import json
from datetime import datetime, timedelta
from flask import Flask, jsonify, request
from flask_cors import CORS
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend access

class DashboardDataService:
    def __init__(self, db_config):
        """Initialize database connection"""
        self.db_config = db_config
        
    def get_connection(self):
        """Get database connection"""
        return psycopg2.connect(**self.db_config)
    
    def execute_query(self, query, params=None):
        """Execute query and return results as DataFrame"""
        try:
            conn = self.get_connection()
            df = pd.read_sql_query(query, conn, params=params)
            conn.close()
            return df
        except Exception as e:
            logger.error(f"Query execution error: {e}")
            raise
    
    def get_kpi_summary(self):
        """Get key performance indicators"""
        query = """
        SELECT 
            COUNT(DISTINCT co2.date_key)           AS total_days,
            AVG(co2.co2_emission_g_kwh)            AS avg_co2_intensity,
            AVG(prod.renewable_percentage)         AS avg_renewable_percentage,
            AVG(prices.spot_price_eur)             AS avg_electricity_price,
            SUM(prod.total_production_mwh)         AS total_energy_production,
            SUM(prod.gross_consumption_mwh)        AS total_energy_consumption
        FROM core.fact_co2_emissions    AS co2
        JOIN core.fact_energy_production AS prod
          ON co2.date_key       = prod.date_key
         AND co2.time_key       = prod.time_key
         AND co2.price_area_key = prod.price_area_key
        JOIN core.fact_electricity_prices AS prices
          ON co2.date_key       = prices.date_key
         AND co2.time_key       = prices.time_key
         AND co2.price_area_key = prices.price_area_key
        WHERE co2.date_key >= TO_CHAR(CURRENT_DATE - INTERVAL '30 days', 'YYYYMMDD')
        """
        return self.execute_query(query)

    
    def get_renewable_trends(self, days=30):
        """Get renewable energy trends over time"""
        query = """
        SELECT 
            d.date_actual,
            pa.price_area_code,
            AVG(prod.renewable_percentage) as renewable_percentage,
            AVG(prod.wind_percentage) as wind_percentage,
            AVG(prod.solar_percentage) as solar_percentage,
            SUM(prod.total_renewable_mwh) as total_renewable_mwh,
            SUM(prod.total_production_mwh) as total_production_mwh
        FROM core.fact_energy_production prod
        JOIN core.dim_date d ON prod.date_key = d.date_key
        JOIN core.dim_price_area pa ON prod.price_area_key = pa.price_area_key
        WHERE d.date_actual >= CURRENT_DATE - INTERVAL '%s days'
            AND pa.is_danish_area = true
        GROUP BY d.date_actual, pa.price_area_code
        ORDER BY d.date_actual, pa.price_area_code
        """
        return self.execute_query(query, (days,))
    
    def get_co2_emissions_analysis(self, days=30):
        """Get CO2 emissions analysis"""
        query = """
        SELECT 
            d.date_actual,
            pa.price_area_code,
            AVG(co2.co2_emission_g_kwh) as avg_co2_intensity,
            MIN(co2.co2_emission_g_kwh) as min_co2_intensity,
            MAX(co2.co2_emission_g_kwh) as max_co2_intensity,
            COUNT(*) as data_points,
            AVG(CASE WHEN t.is_peak_hour THEN co2.co2_emission_g_kwh END) as peak_co2_intensity,
            AVG(CASE WHEN NOT t.is_peak_hour THEN co2.co2_emission_g_kwh END) as offpeak_co2_intensity
        FROM core.fact_co2_emissions co2
        JOIN core.dim_date d ON co2.date_key = d.date_key
        JOIN core.dim_time t ON co2.time_key = t.time_key
        JOIN core.dim_price_area pa ON co2.price_area_key = pa.price_area_key
        WHERE d.date_actual >= CURRENT_DATE - INTERVAL '%s days'
            AND pa.is_danish_area = true
        GROUP BY d.date_actual, pa.price_area_code
        ORDER BY d.date_actual, pa.price_area_code
        """
        return self.execute_query(query, (days,))
    
    def get_price_analysis(self, days=30):
        """Get electricity price analysis"""
        query = """
        SELECT 
            d.date_actual,
            pa.price_area_code,
            AVG(prices.spot_price_eur) as avg_price_eur,
            MIN(prices.spot_price_eur) as min_price_eur,
            MAX(prices.spot_price_eur) as max_price_eur,
            STDDEV(prices.spot_price_eur) as price_volatility,
            COUNT(CASE WHEN prices.is_negative_price THEN 1 END) as negative_price_hours,
            COUNT(CASE WHEN prices.is_price_spike THEN 1 END) as price_spike_hours,
            AVG(CASE WHEN t.is_peak_hour THEN prices.spot_price_eur END) as peak_price_eur,
            AVG(CASE WHEN NOT t.is_peak_hour THEN prices.spot_price_eur END) as offpeak_price_eur
        FROM core.fact_electricity_prices prices
        JOIN core.dim_date d ON prices.date_key = d.date_key
        JOIN core.dim_time t ON prices.time_key = t.time_key
        JOIN core.dim_price_area pa ON prices.price_area_key = pa.price_area_key
        WHERE d.date_actual >= CURRENT_DATE - INTERVAL '%s days'
            AND pa.is_danish_area = true
        GROUP BY d.date_actual, pa.price_area_code
        ORDER BY d.date_actual, pa.price_area_code
        """
        return self.execute_query(query, (days,))
    
    def get_hourly_patterns(self, date_from=None, date_to=None):
        """Get hourly patterns for energy and emissions"""
        if not date_from:
            date_from = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
        if not date_to:
            date_to = datetime.now().strftime('%Y-%m-%d')
            
        query = """
        SELECT 
            t.hour,
            pa.price_area_code,
            AVG(co2.co2_emission_g_kwh) as avg_co2_intensity,
            AVG(prod.renewable_percentage) as avg_renewable_percentage,
            AVG(prices.spot_price_eur) as avg_price_eur,
            SUM(prod.total_production_mwh) as total_production_mwh,
            SUM(prod.gross_consumption_mwh) as total_consumption_mwh,
            COUNT(*) as data_points
        FROM core.fact_co2_emissions co2
        JOIN core.fact_energy_production prod ON co2.date_key = prod.date_key 
            AND co2.time_key = prod.time_key 
            AND co2.price_area_key = prod.price_area_key
        JOIN core.fact_electricity_prices prices ON co2.date_key = prices.date_key 
            AND co2.time_key = prices.time_key 
            AND co2.price_area_key = prices.price_area_key
        JOIN core.dim_date d ON co2.date_key = d.date_key
        JOIN core.dim_time t ON co2.time_key = t.time_key
        JOIN core.dim_price_area pa ON co2.price_area_key = pa.price_area_key
        WHERE d.date_actual BETWEEN %s AND %s
            AND pa.is_danish_area = true
        GROUP BY t.hour, pa.price_area_code
        ORDER BY t.hour, pa.price_area_code
        """
        return self.execute_query(query, (date_from, date_to))
    
    def get_energy_mix_breakdown(self, days=30):
        """Get detailed energy mix breakdown"""
        query = """
        SELECT 
            d.date_actual,
            pa.price_area_code,
            SUM(prod.offshore_wind_lt100mw_mwh + prod.offshore_wind_ge100mw_mwh) as offshore_wind_mwh,
            SUM(prod.onshore_wind_lt50kw_mwh + prod.onshore_wind_ge50kw_mwh) as onshore_wind_mwh,
            SUM(prod.solar_power_lt10kw_mwh + prod.solar_power_ge10lt40kw_mwh + prod.solar_power_ge40kw_mwh) as solar_mwh,
            SUM(prod.hydro_power_mwh) as hydro_mwh,
            SUM(prod.central_power_mwh + prod.local_power_mwh + prod.commercial_power_mwh) as conventional_mwh,
            SUM(prod.total_production_mwh) as total_production_mwh
        FROM core.fact_energy_production prod
        JOIN core.dim_date d ON prod.date_key = d.date_key
        JOIN core.dim_price_area pa ON prod.price_area_key = pa.price_area_key
        WHERE d.date_actual >= CURRENT_DATE - INTERVAL '%s days'
            AND pa.is_danish_area = true
        GROUP BY d.date_actual, pa.price_area_code
        ORDER BY d.date_actual, pa.price_area_code
        """
        return self.execute_query(query, (days,))

# Initialize data service
db_config = {
    'host': 'localhost',
    'database': 'danish_energy_analytics',
    'user': 'postgres',
    'password': 'postgres'
}

data_service = DashboardDataService(db_config)

# API Routes
@app.route('/api/kpis')
def get_kpis():
    """Get key performance indicators"""
    try:
        df = data_service.get_kpi_summary()
        return jsonify(df.to_dict('records')[0] if not df.empty else {})
    except Exception as e:
        logger.error(f"Error in /api/kpis: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/renewable-trends')
def get_renewable_trends():
    """Get renewable energy trends"""
    try:
        days = request.args.get('days', 30, type=int)
        df = data_service.get_renewable_trends(days)
        return jsonify(df.to_dict('records'))
    except Exception as e:
        logger.error(f"Error in /api/renewable-trends: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/co2-analysis')
def get_co2_analysis():
    """Get CO2 emissions analysis"""
    try:
        days = request.args.get('days', 30, type=int)
        df = data_service.get_co2_emissions_analysis(days)
        return jsonify(df.to_dict('records'))
    except Exception as e:
        logger.error(f"Error in /api/co2-analysis: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/price-analysis')
def get_price_analysis():
    """Get electricity price analysis"""
    try:
        days = request.args.get('days', 30, type=int)
        df = data_service.get_price_analysis(days)
        return jsonify(df.to_dict('records'))
    except Exception as e:
        logger.error(f"Error in /api/price-analysis: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/hourly-patterns')
def get_hourly_patterns():
    """Get hourly patterns"""
    try:
        date_from = request.args.get('date_from')
        date_to = request.args.get('date_to')
        df = data_service.get_hourly_patterns(date_from, date_to)
        return jsonify(df.to_dict('records'))
    except Exception as e:
        logger.error(f"Error in /api/hourly-patterns: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/energy-mix')
def get_energy_mix():
    """Get energy mix breakdown"""
    try:
        days = request.args.get('days', 30, type=int)
        df = data_service.get_energy_mix_breakdown(days)
        return jsonify(df.to_dict('records'))
    except Exception as e:
        logger.error(f"Error in /api/energy-mix: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        conn = data_service.get_connection()
        conn.close()
        return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting Danish Energy Analytics Dashboard API...")
    app.run(host='0.0.0.0', port=5000, debug=True)

