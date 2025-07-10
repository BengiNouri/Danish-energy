import os
import logging
import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
from datetime import datetime

# Configure logging…

"""
Data Warehouse Loading Script
Loads the extracted Danish energy data into the PostgreSQL data warehouse
"""

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DataWarehouseLoader:
    def __init__(self, db_config):
        """Initialize database connection"""
        self.db_config = db_config
        self.conn = None
        
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            logger.info("Connected to PostgreSQL database")
        except Exception as e:
            logger.error(f"Error connecting to database: {e}")
            raise
    
    def disconnect(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
            logger.info("Database connection closed")
    
    def load_csv_to_raw_table(self, csv_file_path, table_name, function_name):
        """Load CSV data using PostgreSQL function"""
        try:
            cursor = self.conn.cursor()
            
            # Call the loading function
            cursor.execute(f"SELECT {function_name}(%s);", (csv_file_path,))
            rows_loaded = cursor.fetchone()[0]
            
            self.conn.commit()
            cursor.close()
            
            logger.info(f"Loaded {rows_loaded} rows into {table_name}")
            return rows_loaded
            
        except Exception as e:
            logger.error(f"Error loading {csv_file_path} into {table_name}: {e}")
            if self.conn:
                self.conn.rollback()
            raise
    
    def run_etl_pipeline(self):
        """Execute the ETL pipeline to load fact tables"""
        try:
            cursor = self.conn.cursor()
            
            # Run the ETL pipeline
            cursor.execute("SELECT core.run_etl_pipeline();")
            result = cursor.fetchone()[0]
            
            self.conn.commit()
            cursor.close()
            
            logger.info("ETL Pipeline completed successfully")
            logger.info(result)
            return result
            
        except Exception as e:
            logger.error(f"Error running ETL pipeline: {e}")
            if self.conn:
                self.conn.rollback()
            raise
    
    def get_table_counts(self):
        """Get row counts for all tables"""
        try:
            cursor = self.conn.cursor()
            
            tables = [
                ('raw.co2_emissions', 'Raw CO2 Emissions'),
                ('raw.renewable_energy', 'Raw Renewable Energy'),
                ('raw.electricity_prices', 'Raw Electricity Prices'),
                ('core.dim_date', 'Date Dimension'),
                ('core.dim_time', 'Time Dimension'),
                ('core.dim_price_area', 'Price Area Dimension'),
                ('core.fact_co2_emissions', 'CO2 Emissions Fact'),
                ('core.fact_energy_production', 'Energy Production Fact'),
                ('core.fact_electricity_prices', 'Electricity Prices Fact')
            ]
            
            counts = {}
            for table, description in tables:
                cursor.execute(f"SELECT COUNT(*) FROM {table};")
                count = cursor.fetchone()[0]
                counts[description] = count
                logger.info(f"{description}: {count:,} rows")
            
            cursor.close()
            return counts
            
        except Exception as e:
            logger.error(f"Error getting table counts: {e}")
            raise
    
    def validate_data_quality(self):
        """Run data quality checks"""
        try:
            cursor = self.conn.cursor()
            
            quality_checks = []
            
            # Check for null values in key fields
            cursor.execute("""
                SELECT COUNT(*) as null_co2_values 
                FROM core.fact_co2_emissions 
                WHERE co2_emission_g_kwh IS NULL
            """)
            null_co2 = cursor.fetchone()[0]
            quality_checks.append(f"Null CO2 values: {null_co2}")
            
            # Check for reasonable CO2 values
            cursor.execute("""
                SELECT COUNT(*) as invalid_co2_values 
                FROM core.fact_co2_emissions 
                WHERE co2_emission_g_kwh < 0 OR co2_emission_g_kwh > 1000
            """)
            invalid_co2 = cursor.fetchone()[0]
            quality_checks.append(f"Invalid CO2 values (outside 0-1000): {invalid_co2}")
            
            # Check for negative renewable percentages
            cursor.execute("""
                SELECT COUNT(*) as negative_renewable 
                FROM core.fact_energy_production 
                WHERE renewable_percentage < 0
            """)
            negative_renewable = cursor.fetchone()[0]
            quality_checks.append(f"Negative renewable percentages: {negative_renewable}")
            
            # Check for extreme price values
            cursor.execute("""
                SELECT COUNT(*) as extreme_prices 
                FROM core.fact_electricity_prices 
                WHERE spot_price_eur < -1000 OR spot_price_eur > 5000
            """)
            extreme_prices = cursor.fetchone()[0]
            quality_checks.append(f"Extreme price values: {extreme_prices}")
            
            # Check referential integrity
            cursor.execute("""
                SELECT COUNT(*) as orphaned_co2_records
                FROM core.fact_co2_emissions f
                LEFT JOIN core.dim_date d ON f.date_key = d.date_key
                WHERE d.date_key IS NULL
            """)
            orphaned_co2 = cursor.fetchone()[0]
            quality_checks.append(f"Orphaned CO2 records (missing date): {orphaned_co2}")
            
            cursor.close()
            
            logger.info("Data Quality Check Results:")
            for check in quality_checks:
                logger.info(f"  - {check}")
            
            return quality_checks
            
        except Exception as e:
            logger.error(f"Error running data quality checks: {e}")
            raise

def main():
    """Main execution function"""
    
    # Database configuration
    db_config = {
        'host': 'localhost',
        'database': 'danish_energy_analytics',
        'user': 'postgres',
        'password': 'postgres'  # In production, use environment variables
    }
    
    # Data file paths
    # Data file paths — point at your extracted CSV folder
    base_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.normpath(os.path.join(base_dir, '..', 'data_ingestion', 'raw_data'))

    csv_files = {
        'co2_emissions_raw.csv':      ('raw.co2_emissions',      'raw.load_co2_emissions_from_csv'),
        'renewable_energy_raw.csv':   ('raw.renewable_energy',   'raw.load_renewable_energy_from_csv'),
        'electricity_prices_raw.csv': ('raw.electricity_prices', 'raw.load_electricity_prices_from_csv'),
    }

    
    # Initialize loader
    loader = DataWarehouseLoader(db_config)
    
    try:
        # Connect to database
        loader.connect()
        
        # Load raw data
        logger.info("Starting data warehouse loading process...")
        total_raw_rows = 0
        
        for csv_file, (table_name, function_name) in csv_files.items():
            csv_path = os.path.join(data_dir, csv_file)
            if os.path.exists(csv_path):
                logger.info(f"Loading {csv_file}...")
                rows_loaded = loader.load_csv_to_raw_table(csv_path, table_name, function_name)
                total_raw_rows += rows_loaded
            else:
                logger.warning(f"File not found: {csv_path}")
        
        logger.info(f"Total raw rows loaded: {total_raw_rows:,}")
        
        # Run ETL pipeline to populate fact tables
        logger.info("Running ETL pipeline...")
        etl_result = loader.run_etl_pipeline()
        
        # Get final table counts
        logger.info("Final table counts:")
        counts = loader.get_table_counts()
        
        # Run data quality checks
        logger.info("Running data quality checks...")
        quality_results = loader.validate_data_quality()
        
        # Generate summary report
        summary = f"""
Data Warehouse Loading Summary
==============================
Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Raw Data Loaded:
- Total rows: {total_raw_rows:,}

ETL Results:
{etl_result}

Final Table Counts:
"""
        for table, count in counts.items():
            summary += f"- {table}: {count:,} rows\n"
        
        summary += "\nData Quality Checks:\n"
        for check in quality_results:
            summary += f"- {check}\n"
        
        logger.info(summary)
        
        # Save summary to file
        logger.info(summary)

        # Save summary to file
        base_dir    = os.path.dirname(os.path.abspath(__file__))
        summary_path = os.path.join(base_dir, 'loading_summary.txt')
        with open(summary_path, 'w') as f:
            f.write(summary)

        logger.info("Data warehouse loading completed successfully!")

        
    except Exception as e:
        logger.error(f"Data warehouse loading failed: {e}")
        raise
    finally:
        loader.disconnect()

if __name__ == "__main__":
    main()

