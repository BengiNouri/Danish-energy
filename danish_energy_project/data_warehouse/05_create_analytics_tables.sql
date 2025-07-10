-- Analytics data marts and aggregated tables

-- Daily energy analytics mart
CREATE TABLE IF NOT EXISTS analytics.daily_energy_analytics (
    id BIGSERIAL PRIMARY KEY,
    date_key VARCHAR(8) NOT NULL,
    price_area_key VARCHAR(10) NOT NULL,
    
    -- Production metrics
    total_production_mwh DECIMAL(15,3) DEFAULT 0,
    total_renewable_mwh DECIMAL(15,3) DEFAULT 0,
    total_wind_mwh DECIMAL(15,3) DEFAULT 0,
    total_solar_mwh DECIMAL(15,3) DEFAULT 0,
    total_hydro_mwh DECIMAL(15,3) DEFAULT 0,
    
    -- Consumption metrics
    total_consumption_mwh DECIMAL(15,3) DEFAULT 0,
    total_grid_losses_mwh DECIMAL(15,3) DEFAULT 0,
    total_net_exchange_mwh DECIMAL(15,3) DEFAULT 0,
    
    -- Efficiency metrics
    avg_renewable_percentage DECIMAL(5,2) DEFAULT 0,
    avg_wind_percentage DECIMAL(5,2) DEFAULT 0,
    avg_solar_percentage DECIMAL(5,2) DEFAULT 0,
    avg_grid_efficiency_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Peak analysis
    peak_production_mwh DECIMAL(15,3) DEFAULT 0,
    peak_renewable_mwh DECIMAL(15,3) DEFAULT 0,
    
    -- Emissions metrics
    avg_co2_emission_g_kwh DECIMAL(10,2),
    min_co2_emission_g_kwh DECIMAL(10,2),
    max_co2_emission_g_kwh DECIMAL(10,2),
    stddev_co2_emission_g_kwh DECIMAL(10,2),
    avg_peak_co2_emission_g_kwh DECIMAL(10,2),
    
    -- Price metrics
    avg_spot_price_eur DECIMAL(12,2),
    min_spot_price_eur DECIMAL(12,2),
    max_spot_price_eur DECIMAL(12,2),
    price_volatility_eur DECIMAL(12,2),
    avg_peak_price_eur DECIMAL(12,2),
    price_spike_hours INTEGER DEFAULT 0,
    negative_price_hours INTEGER DEFAULT 0,
    very_high_price_hours INTEGER DEFAULT 0,
    
    -- Calculated KPIs
    daily_renewable_percentage DECIMAL(5,2) DEFAULT 0,
    daily_grid_efficiency_percentage DECIMAL(5,2) DEFAULT 0,
    energy_balance_mwh DECIMAL(15,3) DEFAULT 0,
    
    -- Flags
    is_weekend_day BOOLEAN NOT NULL,
    
    -- Metadata
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT fk_daily_date FOREIGN KEY (date_key) REFERENCES core.dim_date(date_key),
    CONSTRAINT fk_daily_price_area FOREIGN KEY (price_area_key) REFERENCES core.dim_price_area(price_area_key),
    CONSTRAINT pk_daily_analytics UNIQUE (date_key, price_area_key)
);

-- Monthly energy analytics mart
CREATE TABLE IF NOT EXISTS analytics.monthly_energy_analytics (
    id BIGSERIAL PRIMARY KEY,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    price_area_key VARCHAR(10) NOT NULL,
    
    -- Production aggregations
    total_production_mwh DECIMAL(18,3) DEFAULT 0,
    total_renewable_mwh DECIMAL(18,3) DEFAULT 0,
    total_wind_mwh DECIMAL(18,3) DEFAULT 0,
    total_solar_mwh DECIMAL(18,3) DEFAULT 0,
    total_hydro_mwh DECIMAL(18,3) DEFAULT 0,
    
    -- Consumption aggregations
    total_consumption_mwh DECIMAL(18,3) DEFAULT 0,
    total_grid_losses_mwh DECIMAL(18,3) DEFAULT 0,
    total_net_exchange_mwh DECIMAL(18,3) DEFAULT 0,
    
    -- Average metrics
    avg_renewable_percentage DECIMAL(5,2) DEFAULT 0,
    avg_co2_emission_g_kwh DECIMAL(10,2),
    avg_spot_price_eur DECIMAL(12,2),
    
    -- Variability metrics
    renewable_percentage_stddev DECIMAL(5,2),
    co2_emission_stddev DECIMAL(10,2),
    price_volatility_eur DECIMAL(12,2),
    
    -- Extreme values
    max_renewable_percentage DECIMAL(5,2),
    min_co2_emission_g_kwh DECIMAL(10,2),
    max_spot_price_eur DECIMAL(12,2),
    
    -- Count metrics
    total_days INTEGER NOT NULL,
    weekend_days INTEGER NOT NULL,
    high_renewable_days INTEGER DEFAULT 0,
    price_spike_hours INTEGER DEFAULT 0,
    
    -- Metadata
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT fk_monthly_price_area FOREIGN KEY (price_area_key) REFERENCES core.dim_price_area(price_area_key),
    CONSTRAINT chk_month_range CHECK (month BETWEEN 1 AND 12),
    CONSTRAINT pk_monthly_analytics UNIQUE (year, month, price_area_key)
);

-- Energy KPI summary table
CREATE TABLE IF NOT EXISTS analytics.energy_kpi_summary (
    id BIGSERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_category VARCHAR(50) NOT NULL,
    price_area_key VARCHAR(10) NOT NULL,
    time_period VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'yearly'
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    metric_value DECIMAL(18,6) NOT NULL,
    metric_unit VARCHAR(20) NOT NULL,
    benchmark_value DECIMAL(18,6),
    variance_from_benchmark DECIMAL(10,2),
    trend_direction VARCHAR(10), -- 'up', 'down', 'stable'
    confidence_level DECIMAL(5,2),
    data_quality_score DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT fk_kpi_price_area FOREIGN KEY (price_area_key) REFERENCES core.dim_price_area(price_area_key),
    CONSTRAINT chk_confidence_level CHECK (confidence_level BETWEEN 0 AND 100),
    CONSTRAINT chk_data_quality_score CHECK (data_quality_score BETWEEN 0 AND 100)
);

-- Create indexes for analytics tables
CREATE INDEX IF NOT EXISTS idx_daily_analytics_date ON analytics.daily_energy_analytics(date_key);
CREATE INDEX IF NOT EXISTS idx_daily_analytics_area ON analytics.daily_energy_analytics(price_area_key);
CREATE INDEX IF NOT EXISTS idx_daily_analytics_renewable ON analytics.daily_energy_analytics(daily_renewable_percentage);

CREATE INDEX IF NOT EXISTS idx_monthly_analytics_year_month ON analytics.monthly_energy_analytics(year, month);
CREATE INDEX IF NOT EXISTS idx_monthly_analytics_area ON analytics.monthly_energy_analytics(price_area_key);

CREATE INDEX IF NOT EXISTS idx_kpi_summary_metric ON analytics.energy_kpi_summary(metric_name);
CREATE INDEX IF NOT EXISTS idx_kpi_summary_category ON analytics.energy_kpi_summary(metric_category);
CREATE INDEX IF NOT EXISTS idx_kpi_summary_period ON analytics.energy_kpi_summary(time_period, period_start_date);

-- Add table comments
COMMENT ON TABLE analytics.daily_energy_analytics IS 'Daily aggregated energy analytics with KPIs and trends';
COMMENT ON TABLE analytics.monthly_energy_analytics IS 'Monthly aggregated energy analytics for trend analysis';
COMMENT ON TABLE analytics.energy_kpi_summary IS 'Key performance indicators summary across different time periods';

