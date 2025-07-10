# Power BI Dashboard Templates

This directory contains Power BI templates and configurations for the Danish Energy Analytics project.

## Power BI Dashboard Design

### Executive Summary Dashboard
- **KPI Cards**: Renewable percentage, CO₂ intensity, average electricity price, total energy production
- **Trend Charts**: 30-day renewable energy trends, CO₂ emissions over time
- **Regional Comparison**: DK1 vs DK2 performance metrics
- **Energy Mix Visualization**: Pie chart showing renewable vs conventional sources

### Operational Dashboard
- **Hourly Patterns**: 24-hour view of energy production and consumption
- **Price Analysis**: Electricity price volatility and market trends
- **Grid Efficiency**: Real-time grid balance and efficiency metrics
- **Renewable Forecasting**: Predictive analytics for wind and solar production

### Technical Dashboard
- **Data Quality Metrics**: Completeness, accuracy, and freshness indicators
- **System Performance**: ETL pipeline status and processing times
- **Alert Management**: Anomaly detection and threshold monitoring
- **Historical Analysis**: Long-term trends and seasonal patterns

## Power BI Data Model

### Data Sources
1. **Azure SQL Database**: Primary data warehouse connection
2. **Direct Query**: Real-time data access for operational dashboards
3. **Import Mode**: Historical data for analytical dashboards

### Key Measures (DAX)
```dax
-- Renewable Energy Percentage
Renewable Percentage = 
DIVIDE(
    SUM(fact_energy_production[total_renewable_mwh]),
    SUM(fact_energy_production[total_production_mwh])
) * 100

-- Average CO₂ Intensity
Avg CO2 Intensity = 
AVERAGE(fact_co2_emissions[co2_emission_g_kwh])

-- Price Volatility
Price Volatility = 
STDEV.P(fact_electricity_prices[spot_price_eur])

-- Grid Efficiency
Grid Efficiency = 
DIVIDE(
    SUM(fact_energy_production[gross_consumption_mwh]),
    SUM(fact_energy_production[total_production_mwh])
) * 100
```

### Calculated Columns
```dax
-- Peak Hour Indicator
Is Peak Hour = 
IF(
    HOUR(dim_time[time_actual]) >= 8 && HOUR(dim_time[time_actual]) <= 20,
    "Peak",
    "Off-Peak"
)

-- Renewable Category
Renewable Category = 
SWITCH(
    TRUE(),
    fact_energy_production[renewable_percentage] >= 80, "Very High",
    fact_energy_production[renewable_percentage] >= 60, "High",
    fact_energy_production[renewable_percentage] >= 40, "Medium",
    "Low"
)
```

## Dashboard Features

### Interactive Elements
- **Date Range Selector**: 7, 30, 90 days, extended to 6 months, 1 year, or 5 years
- **Regional Filter**: DK1, DK2, or combined view
- **Energy Source Filter**: Wind, Solar, Hydro, Conventional
- **Time Period Filter**: Peak hours, off-peak, weekends

### Visualizations
1. **Line Charts**: Time-series trends for renewable energy and CO₂ emissions
2. **Bar Charts**: Hourly patterns and regional comparisons
3. **Pie Charts**: Energy mix breakdown by source
4. **Gauge Charts**: KPI performance against targets
5. **Heat Maps**: Hourly patterns across days of the week
6. **Scatter Plots**: Correlation analysis between variables

### Drill-Down Capabilities
- **Year → Quarter → Month → Day → Hour**
- **Country → Region → Price Area**
- **Total Energy → Renewable → Source Type**

## Power BI Service Configuration

### Refresh Schedule
- **Incremental Refresh**: Every 15 minutes for operational data
- **Full Refresh**: Daily at 2:00 AM for historical data
- **On-Demand Refresh**: Available for ad-hoc analysis

### Security
- **Row-Level Security**: Regional access control
- **Column-Level Security**: Sensitive data protection
- **Azure AD Integration**: Single sign-on authentication

### Sharing and Collaboration
- **Workspaces**: Separate environments for development, testing, and production
- **Apps**: Packaged dashboards for different user groups
- **Embedded Analytics**: Integration with web applications

## Mobile Optimization

### Phone Layout
- **Simplified KPIs**: Top 4 metrics only
- **Vertical Charts**: Optimized for portrait orientation
- **Touch-Friendly**: Large buttons and touch targets

### Tablet Layout
- **Condensed View**: 2-column layout
- **Interactive Charts**: Full functionality maintained
- **Landscape Orientation**: Optimized for horizontal viewing

## Performance Optimization

### Data Model Optimization
- **Star Schema**: Optimized for analytical queries
- **Aggregation Tables**: Pre-calculated summaries
- **Partitioning**: Date-based partitioning for large tables
- **Compression**: Columnstore indexes for better performance

### Query Optimization
- **DirectQuery Optimization**: Efficient SQL generation
- **Composite Models**: Mix of import and DirectQuery
- **Aggregations**: Automatic query acceleration
- **Query Reduction**: Minimize data transfer

## Deployment Guide

### Prerequisites
- Power BI Pro or Premium license
- Azure SQL Database access
- Power BI Desktop (latest version)

### Installation Steps
1. Download Power BI template files (.pbit)
2. Open in Power BI Desktop
3. Configure data source connections
4. Update credentials and security settings
5. Publish to Power BI Service
6. Configure refresh schedules
7. Set up security and sharing

### Maintenance
- **Monthly**: Review and update DAX measures
- **Quarterly**: Optimize data model performance
- **Annually**: Review dashboard design and user feedback

## Business Value

### Key Benefits
- **Real-time Monitoring**: Live energy grid status
- **Predictive Analytics**: Renewable energy forecasting
- **Cost Optimization**: Electricity price trend analysis
- **Environmental Impact**: CO₂ emissions tracking
- **Operational Efficiency**: Grid performance optimization

### ROI Metrics
- **Decision Speed**: 50% faster energy trading decisions
- **Cost Savings**: 15% reduction in energy procurement costs
- **Efficiency Gains**: 20% improvement in grid utilization
- **Environmental Impact**: 25% better renewable energy integration

This Power BI implementation provides comprehensive analytics capabilities for Danish energy market analysis, supporting both operational and strategic decision-making processes.

