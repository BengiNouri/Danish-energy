"""
Star Schema Design for Danish Energy Analytics
=============================================

This document outlines the dimensional model design for the Danish energy analytics project.
The star schema is optimized for analytical queries and reporting on energy consumption,
production, emissions, and pricing data.

Author: Manus AI
Date: 2025-06-15
"""

# Star Schema Design

## Overview
The star schema consists of fact tables containing measurable events and dimension tables
containing descriptive attributes. This design enables efficient analytical queries and
supports the business questions defined in the project scope.

## Fact Tables

### 1. fact_energy_production
**Purpose**: Records energy production by source, time, and location
**Grain**: One row per hour, price area, and energy source

**Measures**:
- central_power_mwh: Central power production
- local_power_mwh: Local power production  
- commercial_power_mwh: Commercial power production
- offshore_wind_lt100mw_mwh: Offshore wind <100MW
- offshore_wind_ge100mw_mwh: Offshore wind >=100MW
- onshore_wind_lt50kw_mwh: Onshore wind <50kW
- onshore_wind_ge50kw_mwh: Onshore wind >=50kW
- hydro_power_mwh: Hydro power production
- solar_power_lt10kw_mwh: Solar power <10kW
- solar_power_ge10lt40kw_mwh: Solar power 10-40kW
- solar_power_ge40kw_mwh: Solar power >=40kW
- total_renewable_mwh: Total renewable production
- total_production_mwh: Total energy production

**Foreign Keys**:
- date_key: Links to dim_date
- time_key: Links to dim_time
- price_area_key: Links to dim_price_area
- energy_source_key: Links to dim_energy_source

### 2. fact_energy_consumption
**Purpose**: Records energy consumption by time and location
**Grain**: One row per hour and price area

**Measures**:
- gross_consumption_mwh: Total gross consumption
- grid_loss_transmission_mwh: Transmission losses
- grid_loss_interconnectors_mwh: Interconnector losses
- grid_loss_distribution_mwh: Distribution losses
- power_to_heat_mwh: Power-to-heat consumption
- net_consumption_mwh: Net consumption (calculated)

**Foreign Keys**:
- date_key: Links to dim_date
- time_key: Links to dim_time
- price_area_key: Links to dim_price_area

### 3. fact_co2_emissions
**Purpose**: Records CO2 emissions by time and location
**Grain**: One row per 5-minute interval and price area

**Measures**:
- co2_emission_g_kwh: CO2 emissions in grams per kWh
- co2_emission_total_kg: Total CO2 emissions in kg (calculated)

**Foreign Keys**:
- date_key: Links to dim_date
- time_key: Links to dim_time
- price_area_key: Links to dim_price_area

### 4. fact_electricity_prices
**Purpose**: Records electricity spot prices by time and market area
**Grain**: One row per hour and price area

**Measures**:
- spot_price_dkk: Spot price in Danish Kroner
- spot_price_eur: Spot price in Euros
- price_volatility: Price volatility indicator (calculated)

**Foreign Keys**:
- date_key: Links to dim_date
- time_key: Links to dim_time
- price_area_key: Links to dim_price_area

### 5. fact_energy_exchange
**Purpose**: Records energy exchange between regions
**Grain**: One row per hour, price area, and exchange direction

**Measures**:
- exchange_no_mwh: Exchange with Norway
- exchange_se_mwh: Exchange with Sweden
- exchange_ge_mwh: Exchange with Germany
- exchange_nl_mwh: Exchange with Netherlands
- exchange_gb_mwh: Exchange with Great Britain
- exchange_great_belt_mwh: Exchange via Great Belt
- net_exchange_mwh: Net exchange (calculated)

**Foreign Keys**:
- date_key: Links to dim_date
- time_key: Links to dim_time
- price_area_key: Links to dim_price_area

## Dimension Tables

### 1. dim_date
**Purpose**: Date dimension for time-based analysis
**Type**: Type 1 SCD (no history tracking needed)

**Attributes**:
- date_key: Surrogate key (YYYYMMDD format)
- date_actual: Actual date
- year: Year (2020-2024)
- quarter: Quarter (Q1-Q4)
- month: Month (1-12)
- month_name: Month name (January-December)
- week: Week number (1-53)
- day_of_year: Day of year (1-366)
- day_of_month: Day of month (1-31)
- day_of_week: Day of week (1-7)
- day_name: Day name (Monday-Sunday)
- is_weekend: Weekend indicator (Y/N)
- is_holiday: Holiday indicator (Y/N)
- season: Season (Spring, Summer, Autumn, Winter)

### 2. dim_time
**Purpose**: Time dimension for intraday analysis
**Type**: Type 1 SCD

**Attributes**:
- time_key: Surrogate key
- hour: Hour (0-23)
- minute: Minute (0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55)
- time_of_day: Time period (Night, Morning, Afternoon, Evening)
- is_peak_hour: Peak hour indicator (Y/N)
- is_business_hour: Business hour indicator (Y/N)

### 3. dim_price_area
**Purpose**: Geographic/market area dimension
**Type**: Type 1 SCD

**Attributes**:
- price_area_key: Surrogate key
- price_area_code: Area code (DK1, DK2, DE, NO2, SE3, SE4, etc.)
- price_area_name: Full area name
- country: Country name
- region: Region name
- is_danish_area: Danish area indicator (Y/N)
- grid_operator: Grid operator name

### 4. dim_energy_source
**Purpose**: Energy source classification dimension
**Type**: Type 1 SCD

**Attributes**:
- energy_source_key: Surrogate key
- source_code: Source code
- source_name: Source name
- source_category: Category (Renewable, Fossil, Nuclear, Other)
- source_type: Type (Wind, Solar, Hydro, Coal, Gas, etc.)
- is_renewable: Renewable indicator (Y/N)
- is_variable: Variable output indicator (Y/N)
- carbon_intensity: Typical carbon intensity (g CO2/kWh)

### 5. dim_weather (Future Enhancement)
**Purpose**: Weather data for correlation analysis
**Type**: Type 1 SCD

**Attributes**:
- weather_key: Surrogate key
- temperature_avg: Average temperature
- wind_speed_avg: Average wind speed
- solar_irradiance: Solar irradiance
- precipitation: Precipitation amount
- weather_condition: Weather condition category

## Calculated Measures and KPIs

### Energy Mix Analysis
- renewable_percentage: (total_renewable_mwh / total_production_mwh) * 100
- wind_percentage: (total_wind_mwh / total_production_mwh) * 100
- solar_percentage: (total_solar_mwh / total_production_mwh) * 100

### Efficiency Metrics
- grid_efficiency: (net_consumption_mwh / gross_consumption_mwh) * 100
- transmission_loss_rate: (grid_loss_transmission_mwh / gross_consumption_mwh) * 100

### Environmental Metrics
- carbon_intensity_avg: Total CO2 emissions / Total energy production
- emission_reduction_rate: Year-over-year change in carbon intensity

### Economic Metrics
- price_volatility: Standard deviation of hourly prices
- renewable_price_correlation: Correlation between renewable % and prices

## Data Quality Rules

### Fact Table Constraints
1. All measure values must be >= 0
2. Date and time keys must exist in dimension tables
3. CO2 emissions must be between 0 and 1000 g/kWh
4. Prices must be between -1000 and 20000 DKK/MWh

### Dimension Table Constraints
1. All dimension keys must be unique
2. Date dimension must cover complete date range
3. Price area codes must follow standard format

### Business Rules
1. Total production should approximately equal consumption + losses + exports
2. Renewable percentage should be between 0% and 100%
3. CO2 emissions should correlate inversely with renewable percentage

## Implementation Notes

### Indexing Strategy
- Clustered indexes on date_key for all fact tables
- Non-clustered indexes on frequently queried dimension attributes
- Composite indexes on common query patterns (date + price_area)

### Partitioning Strategy
- Partition fact tables by year for performance
- Consider monthly partitioning for large fact tables

### Aggregation Strategy
- Pre-aggregate daily and monthly summaries
- Create materialized views for common KPIs
- Implement incremental refresh for performance

This star schema design provides a solid foundation for analytical queries while maintaining
data integrity and performance optimization for the Danish energy analytics project.

