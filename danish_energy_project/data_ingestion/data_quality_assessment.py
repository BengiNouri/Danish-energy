"""
Data Quality Assessment and Validation Script
=============================================

This script performs data quality checks on the extracted Danish energy data
and provides insights into data completeness, accuracy, and structure.

Author: Manus AI
Date: 2025-06-15
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import os
import json
import warnings
warnings.filterwarnings('ignore')

class DataQualityAssessment:
    """
    Class for performing comprehensive data quality assessment
    """
    
    def __init__(self, data_dir: str = "raw_data"):
        """
        Initialize the data quality assessment
        
        Args:
            data_dir: Directory containing raw data files
        """
        self.data_dir = data_dir
        self.report = {}
        
    def load_datasets(self):
        """Load all extracted datasets"""
        datasets = {}
        
        # Load CO2 emissions data
        co2_file = os.path.join(self.data_dir, 'co2_emissions_raw.csv')
        if os.path.exists(co2_file):
            datasets['co2_emissions'] = pd.read_csv(co2_file)
            print(f"Loaded CO2 emissions data: {len(datasets['co2_emissions'])} records")
        
        # Load renewable energy data
        renewable_file = os.path.join(self.data_dir, 'renewable_energy_raw.csv')
        if os.path.exists(renewable_file):
            datasets['renewable_energy'] = pd.read_csv(renewable_file)
            print(f"Loaded renewable energy data: {len(datasets['renewable_energy'])} records")
        
        # Load electricity prices data
        prices_file = os.path.join(self.data_dir, 'electricity_prices_raw.csv')
        if os.path.exists(prices_file):
            datasets['electricity_prices'] = pd.read_csv(prices_file)
            print(f"Loaded electricity prices data: {len(datasets['electricity_prices'])} records")
        
        return datasets
    
    def assess_data_quality(self, datasets):
        """
        Perform comprehensive data quality assessment
        
        Args:
            datasets: Dictionary of loaded datasets
        """
        print("\\n" + "="*50)
        print("DATA QUALITY ASSESSMENT REPORT")
        print("="*50)
        
        for name, df in datasets.items():
            print(f"\\n--- {name.upper()} DATASET ---")
            
            # Basic statistics
            print(f"Shape: {df.shape}")
            print(f"Memory usage: {df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
            
            # Missing values
            missing_values = df.isnull().sum()
            missing_pct = (missing_values / len(df)) * 100
            
            print("\\nMissing Values:")
            for col in df.columns:
                if missing_values[col] > 0:
                    print(f"  {col}: {missing_values[col]} ({missing_pct[col]:.2f}%)")
            
            # Data types
            print("\\nData Types:")
            for col, dtype in df.dtypes.items():
                print(f"  {col}: {dtype}")
            
            # Date range analysis
            date_cols = [col for col in df.columns if 'UTC' in col or 'DK' in col or 'Hour' in col or 'Minutes' in col]
            if date_cols:
                print(f"\\nDate Range Analysis:")
                for date_col in date_cols[:2]:  # Check first 2 date columns
                    try:
                        df[date_col] = pd.to_datetime(df[date_col])
                        print(f"  {date_col}: {df[date_col].min()} to {df[date_col].max()}")
                        print(f"  Duration: {(df[date_col].max() - df[date_col].min()).days} days")
                    except:
                        print(f"  {date_col}: Could not parse as datetime")
            
            # Numerical columns analysis
            numeric_cols = df.select_dtypes(include=[np.number]).columns
            if len(numeric_cols) > 0:
                print(f"\\nNumerical Columns Summary:")
                print(df[numeric_cols].describe())
            
            # Store in report
            self.report[name] = {
                'shape': df.shape,
                'missing_values': missing_values.to_dict(),
                'data_types': df.dtypes.to_dict(),
                'memory_usage_mb': df.memory_usage(deep=True).sum() / 1024**2
            }
    
    def analyze_co2_emissions(self, df):
        """
        Specific analysis for CO2 emissions data
        
        Args:
            df: CO2 emissions DataFrame
        """
        print("\\n" + "="*50)
        print("CO2 EMISSIONS DETAILED ANALYSIS")
        print("="*50)
        
        # Convert datetime columns
        df['Minutes5UTC'] = pd.to_datetime(df['Minutes5UTC'])
        df['Minutes5DK'] = pd.to_datetime(df['Minutes5DK'])
        
        # Price area analysis
        print("\\nPrice Area Distribution:")
        print(df['PriceArea'].value_counts())
        
        # CO2 emission statistics
        print("\\nCO2 Emission Statistics:")
        print(df['CO2Emission'].describe())
        
        # Time series analysis
        print("\\nTime Series Coverage:")
        print(f"First record: {df['Minutes5UTC'].min()}")
        print(f"Last record: {df['Minutes5UTC'].max()}")
        print(f"Total duration: {(df['Minutes5UTC'].max() - df['Minutes5UTC'].min()).days} days")
        
        # Check for data gaps
        df_sorted = df.sort_values('Minutes5UTC')
        time_diffs = df_sorted['Minutes5UTC'].diff()
        expected_interval = pd.Timedelta(minutes=5)
        gaps = time_diffs[time_diffs > expected_interval]
        
        print(f"\\nData Gaps Analysis:")
        print(f"Expected interval: 5 minutes")
        print(f"Number of gaps > 5 minutes: {len(gaps)}")
        if len(gaps) > 0:
            print(f"Largest gap: {gaps.max()}")
        
        # Average emissions by price area
        print("\\nAverage CO2 Emissions by Price Area:")
        avg_emissions = df.groupby('PriceArea')['CO2Emission'].agg(['mean', 'std', 'min', 'max'])
        print(avg_emissions)
        
        return avg_emissions
    
    def analyze_renewable_energy(self, df):
        """
        Specific analysis for renewable energy data
        
        Args:
            df: Renewable energy DataFrame
        """
        print("\\n" + "="*50)
        print("RENEWABLE ENERGY DETAILED ANALYSIS")
        print("="*50)
        
        # Convert datetime columns
        df['HourUTC'] = pd.to_datetime(df['HourUTC'])
        df['HourDK'] = pd.to_datetime(df['HourDK'])
        
        # Renewable energy columns
        renewable_cols = [col for col in df.columns if any(keyword in col.lower() 
                         for keyword in ['wind', 'solar', 'hydro'])]
        
        print(f"\\nRenewable Energy Sources Identified:")
        for col in renewable_cols:
            print(f"  {col}")
        
        # Calculate total renewable production
        if renewable_cols:
            df['TotalRenewableMWh'] = df[renewable_cols].sum(axis=1)
            
            print("\\nRenewable Energy Statistics (MWh):")
            renewable_stats = df[renewable_cols + ['TotalRenewableMWh']].describe()
            print(renewable_stats)
            
            # Price area comparison
            print("\\nRenewable Production by Price Area:")
            renewable_by_area = df.groupby('PriceArea')['TotalRenewableMWh'].agg(['mean', 'sum'])
            print(renewable_by_area)
        
        # Consumption analysis
        consumption_cols = [col for col in df.columns if 'consumption' in col.lower()]
        if 'GrossConsumptionMWh' in df.columns:
            print("\\nConsumption Statistics:")
            print(df['GrossConsumptionMWh'].describe())
        
        return df
    
    def analyze_electricity_prices(self, df):
        """
        Specific analysis for electricity prices data
        
        Args:
            df: Electricity prices DataFrame
        """
        print("\\n" + "="*50)
        print("ELECTRICITY PRICES DETAILED ANALYSIS")
        print("="*50)
        
        # Convert datetime columns
        df['HourUTC'] = pd.to_datetime(df['HourUTC'])
        df['HourDK'] = pd.to_datetime(df['HourDK'])
        
        # Price area analysis
        print("\\nPrice Area Distribution:")
        print(df['PriceArea'].value_counts())
        
        # Price statistics
        print("\\nPrice Statistics (DKK):")
        print(df['SpotPriceDKK'].describe())
        
        print("\\nPrice Statistics (EUR):")
        print(df['SpotPriceEUR'].describe())
        
        # Average prices by area
        print("\\nAverage Prices by Area:")
        price_by_area = df.groupby('PriceArea')[['SpotPriceDKK', 'SpotPriceEUR']].agg(['mean', 'std'])
        print(price_by_area)
        
        # Check for extreme prices
        high_prices_dkk = df[df['SpotPriceDKK'] > df['SpotPriceDKK'].quantile(0.95)]
        print(f"\\nHigh Price Events (>95th percentile):")
        print(f"Number of high price hours: {len(high_prices_dkk)}")
        if len(high_prices_dkk) > 0:
            print(f"Highest price: {high_prices_dkk['SpotPriceDKK'].max():.2f} DKK")
        
        return df
    
    def generate_summary_report(self):
        """Generate and save summary report"""
        summary = {
            'assessment_date': datetime.now().isoformat(),
            'datasets_analyzed': list(self.report.keys()),
            'total_records': sum([info['shape'][0] for info in self.report.values()]),
            'total_memory_mb': sum([info['memory_usage_mb'] for info in self.report.values()]),
            'data_quality_summary': self.report
        }
        
        # Save report
        with open('data_quality_report.json', 'w') as f:
            json.dump(summary, f, indent=2, default=str)
        
        print("\\n" + "="*50)
        print("SUMMARY REPORT")
        print("="*50)
        print(f"Total datasets analyzed: {len(self.report)}")
        print(f"Total records: {summary['total_records']:,}")
        print(f"Total memory usage: {summary['total_memory_mb']:.2f} MB")
        print(f"Report saved to: data_quality_report.json")
        
        return summary

def main():
    """Main execution function"""
    print("Starting Data Quality Assessment...")
    
    # Initialize assessment
    dqa = DataQualityAssessment()
    
    # Load datasets
    datasets = dqa.load_datasets()
    
    if not datasets:
        print("No datasets found. Please run data extraction first.")
        return
    
    # Perform general quality assessment
    dqa.assess_data_quality(datasets)
    
    # Perform specific analyses
    if 'co2_emissions' in datasets:
        dqa.analyze_co2_emissions(datasets['co2_emissions'])
    
    if 'renewable_energy' in datasets:
        datasets['renewable_energy'] = dqa.analyze_renewable_energy(datasets['renewable_energy'])
    
    if 'electricity_prices' in datasets:
        dqa.analyze_electricity_prices(datasets['electricity_prices'])
    
    # Generate summary report
    summary = dqa.generate_summary_report()
    
    print("\\nData Quality Assessment completed successfully!")

if __name__ == "__main__":
    main()

