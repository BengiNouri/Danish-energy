"""
Danish Energy Data Extraction Script
====================================

This script extracts energy and emissions data from Danish official sources:
1. Energi Data Service API (Energinet)
2. Danish Energy Agency statistics
3. Statistics Denmark

Author: Manus AI
Date: 2025-06-15
"""

import requests
import pandas as pd
import json
from datetime import datetime, timedelta
import os
import logging
from typing import Dict, List, Optional
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('data_extraction.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class DanishEnergyDataExtractor:
    """
    Main class for extracting Danish energy and emissions data
    """
    
    def __init__(self, output_dir: str = "raw_data"):
        """
        Initialize the data extractor
        
        Args:
            output_dir: Directory to save extracted data
        """
        self.output_dir = output_dir
        self.base_api_url = "https://api.energidataservice.dk"
        self.session = requests.Session()
        
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        logger.info(f"Initialized DanishEnergyDataExtractor with output directory: {output_dir}")
    
    def get_dataset_list(self) -> List[Dict]:
        """
        Get list of available datasets from Energi Data Service
        
        Returns:
            List of dataset metadata
        """
        try:
            url = f"{self.base_api_url}/meta/dataset"
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            logger.info(f"Retrieved {len(data.get('result', []))} datasets")
            
            # Save dataset list for reference
            with open(os.path.join(self.output_dir, 'available_datasets.json'), 'w') as f:
                json.dump(data, f, indent=2)
            
            return data.get('result', [])
            
        except Exception as e:
            logger.error(f"Error fetching dataset list: {e}")
            return []
    
    def extract_electricity_data(self, start_date: str = "2020-01-01", end_date: str = "2024-12-31") -> pd.DataFrame:
        """
        Extract electricity production and consumption data
        
        Args:
            start_date: Start date in YYYY-MM-DD format
            end_date: End date in YYYY-MM-DD format
            
        Returns:
            DataFrame with electricity data
        """
        try:
            # Get electricity balance data
            url = f"{self.base_api_url}/dataset/ElectricityBalance"
            params = {
                'start': start_date,
                'end': end_date,
                'format': 'json'
            }
            
            logger.info(f"Extracting electricity data from {start_date} to {end_date}")
            response = self.session.get(url, params=params, timeout=60)
            response.raise_for_status()
            
            data = response.json()
            records = data.get('records', [])
            
            if records:
                df = pd.DataFrame(records)
                
                # Save raw data
                output_file = os.path.join(self.output_dir, 'electricity_balance_raw.csv')
                df.to_csv(output_file, index=False)
                logger.info(f"Saved {len(df)} electricity records to {output_file}")
                
                return df
            else:
                logger.warning("No electricity data found")
                return pd.DataFrame()
                
        except Exception as e:
            logger.error(f"Error extracting electricity data: {e}")
            return pd.DataFrame()
    
    def extract_co2_emissions_data(self, start_date: str = "2020-01-01", end_date: str = "2024-12-31") -> pd.DataFrame:
        """
        Extract CO2 emissions data
        
        Args:
            start_date: Start date in YYYY-MM-DD format
            end_date: End date in YYYY-MM-DD format
            
        Returns:
            DataFrame with CO2 emissions data
        """
        try:
            # Get CO2 emission prognosis data
            url = f"{self.base_api_url}/dataset/CO2Emis"
            params = {
                'start': start_date,
                'end': end_date,
                'format': 'json'
            }
            
            logger.info(f"Extracting CO2 emissions data from {start_date} to {end_date}")
            response = self.session.get(url, params=params, timeout=60)
            response.raise_for_status()
            
            data = response.json()
            records = data.get('records', [])
            
            if records:
                df = pd.DataFrame(records)
                
                # Save raw data
                output_file = os.path.join(self.output_dir, 'co2_emissions_raw.csv')
                df.to_csv(output_file, index=False)
                logger.info(f"Saved {len(df)} CO2 emission records to {output_file}")
                
                return df
            else:
                logger.warning("No CO2 emissions data found")
                return pd.DataFrame()
                
        except Exception as e:
            logger.error(f"Error extracting CO2 emissions data: {e}")
            return pd.DataFrame()
    
    def extract_renewable_energy_data(self, start_date: str = "2020-01-01", end_date: str = "2024-12-31") -> pd.DataFrame:
        """
        Extract renewable energy production data
        
        Args:
            start_date: Start date in YYYY-MM-DD format
            end_date: End date in YYYY-MM-DD format
            
        Returns:
            DataFrame with renewable energy data
        """
        try:
            # Get production data by technology
            url = f"{self.base_api_url}/dataset/ProductionConsumptionSettlement"
            params = {
                'start': start_date,
                'end': end_date,
                'format': 'json'
            }
            
            logger.info(f"Extracting renewable energy data from {start_date} to {end_date}")
            response = self.session.get(url, params=params, timeout=60)
            response.raise_for_status()
            
            data = response.json()
            records = data.get('records', [])
            
            if records:
                df = pd.DataFrame(records)
                
                # Save raw data
                output_file = os.path.join(self.output_dir, 'renewable_energy_raw.csv')
                df.to_csv(output_file, index=False)
                logger.info(f"Saved {len(df)} renewable energy records to {output_file}")
                
                return df
            else:
                logger.warning("No renewable energy data found")
                return pd.DataFrame()
                
        except Exception as e:
            logger.error(f"Error extracting renewable energy data: {e}")
            return pd.DataFrame()
    
    def extract_electricity_prices(self, start_date: str = "2020-01-01", end_date: str = "2024-12-31") -> pd.DataFrame:
        """
        Extract electricity price data
        
        Args:
            start_date: Start date in YYYY-MM-DD format
            end_date: End date in YYYY-MM-DD format
            
        Returns:
            DataFrame with electricity price data
        """
        try:
            # Get Elspot prices
            url = f"{self.base_api_url}/dataset/Elspotprices"
            params = {
                'start': start_date,
                'end': end_date,
                'format': 'json'
            }
            
            logger.info(f"Extracting electricity price data from {start_date} to {end_date}")
            response = self.session.get(url, params=params, timeout=60)
            response.raise_for_status()
            
            data = response.json()
            records = data.get('records', [])
            
            if records:
                df = pd.DataFrame(records)
                
                # Save raw data
                output_file = os.path.join(self.output_dir, 'electricity_prices_raw.csv')
                df.to_csv(output_file, index=False)
                logger.info(f"Saved {len(df)} electricity price records to {output_file}")
                
                return df
            else:
                logger.warning("No electricity price data found")
                return pd.DataFrame()
                
        except Exception as e:
            logger.error(f"Error extracting electricity price data: {e}")
            return pd.DataFrame()
    
    def run_full_extraction(self, start_date: str = "2020-01-01", end_date: str = "2024-12-31"):
        """
        Run complete data extraction process
        
        Args:
            start_date: Start date in YYYY-MM-DD format
            end_date: End date in YYYY-MM-DD format
        """
        logger.info("Starting full data extraction process")
        
        # Get available datasets first
        datasets = self.get_dataset_list()
        
        # Extract all data types
        electricity_df = self.extract_electricity_data(start_date, end_date)
        co2_df = self.extract_co2_emissions_data(start_date, end_date)
        renewable_df = self.extract_renewable_energy_data(start_date, end_date)
        prices_df = self.extract_electricity_prices(start_date, end_date)
        
        # Create summary report
        summary = {
            'extraction_date': datetime.now().isoformat(),
            'date_range': f"{start_date} to {end_date}",
            'datasets_extracted': {
                'electricity_balance': len(electricity_df),
                'co2_emissions': len(co2_df),
                'renewable_energy': len(renewable_df),
                'electricity_prices': len(prices_df)
            },
            'total_records': len(electricity_df) + len(co2_df) + len(renewable_df) + len(prices_df)
        }
        
        # Save summary
        with open(os.path.join(self.output_dir, 'extraction_summary.json'), 'w') as f:
            json.dump(summary, f, indent=2)
        
        logger.info(f"Data extraction completed. Total records: {summary['total_records']}")
        return summary

if __name__ == "__main__":
    # Initialize extractor
    extractor = DanishEnergyDataExtractor(output_dir="raw_data")
    
    # Run extraction for the last 5 years
    summary = extractor.run_full_extraction(
        start_date="2020-01-01",
        end_date="2025-07-10"
    )
    
    print(f"Extraction completed. Summary: {summary}")

