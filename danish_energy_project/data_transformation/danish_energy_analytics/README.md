# Danish Energy Analytics dbt Project

## Overview
This dbt project transforms raw Danish energy data into a star schema optimized for analytics.
The project includes staging models, dimension tables, fact tables, and data marts.

## Project Structure
```
models/
├── staging/          # Raw data cleaning and standardization
├── intermediate/     # Business logic transformations
├── marts/           # Final dimensional models
│   ├── core/        # Core business entities
│   └── analytics/   # Analytics-ready data marts
└── utils/           # Utility models and macros
```

## Data Sources
- CO2 emissions data (5-minute intervals)
- Renewable energy production (hourly)
- Electricity prices (hourly)
- Energy consumption and exchange data

## Key Models
- `dim_date`: Date dimension with business calendar
- `dim_time`: Time dimension for intraday analysis
- `dim_price_area`: Geographic market areas
- `fact_energy_production`: Energy production by source
- `fact_co2_emissions`: CO2 emissions tracking
- `fact_electricity_prices`: Market price data

## Usage
1. Configure connection in `profiles.yml`
2. Run `dbt deps` to install dependencies
3. Run `dbt seed` to load reference data
4. Run `dbt run` to build all models
5. Run `dbt test` to validate data quality

## Documentation
Run `dbt docs generate` and `dbt docs serve` to view model documentation.

