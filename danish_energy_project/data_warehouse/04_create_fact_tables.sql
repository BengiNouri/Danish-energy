-- Core fact tables for the star schema

-- CO2 emissions fact table
CREATE TABLE IF NOT EXISTS core.fact_co2_emissions (
    id BIGSERIAL PRIMARY KEY,
    date_key VARCHAR(8) NOT NULL,
    time_key VARCHAR(4) NOT NULL,
    price_area_key VARCHAR(10) NOT NULL,
    co2_emission_g_kwh DECIMAL(10,2) NOT NULL,
    emission_category VARCHAR(20) NOT NULL,
    is_peak_hour BOOLEAN NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    timestamp_utc TIMESTAMP NOT NULL,
    timestamp_dk TIMESTAMP NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_co2_date FOREIGN KEY (date_key) REFERENCES core.dim_date(date_key),
    CONSTRAINT fk_co2_time FOREIGN KEY (time_key) REFERENCES core.dim_time(time_key),
    CONSTRAINT fk_co2_price_area FOREIGN KEY (price_area_key) REFERENCES core.dim_price_area(price_area_key),
    
    -- Data quality constraints
    CONSTRAINT chk_co2_emission_valid CHECK (co2_emission_g_kwh >= 0 AND co2_emission_g_kwh <= 1000)
);

-- Energy production fact table
CREATE TABLE IF NOT EXISTS core.fact_energy_production (
    id BIGSERIAL PRIMARY KEY,
    date_key VARCHAR(8) NOT NULL,
    time_key VARCHAR(4) NOT NULL,
    price_area_key VARCHAR(10) NOT NULL,
    
    -- Production measures
    central_power_mwh DECIMAL(12,3) DEFAULT 0,
    local_power_mwh DECIMAL(12,3) DEFAULT 0,
    commercial_power_mwh DECIMAL(12,3) DEFAULT 0,
    local_power_self_con_mwh DECIMAL(12,3) DEFAULT 0,
    
    -- Wind power measures
    offshore_wind_lt100mw_mwh DECIMAL(12,3) DEFAULT 0,
    offshore_wind_ge100mw_mwh DECIMAL(12,3) DEFAULT 0,
    onshore_wind_lt50kw_mwh DECIMAL(12,3) DEFAULT 0,
    onshore_wind_ge50kw_mwh DECIMAL(12,3) DEFAULT 0,
    total_wind_mwh DECIMAL(12,3) DEFAULT 0,
    
    -- Other renewable measures
    hydro_power_mwh DECIMAL(12,3) DEFAULT 0,
    solar_power_lt10kw_mwh DECIMAL(12,3) DEFAULT 0,
    solar_power_ge10lt40kw_mwh DECIMAL(12,3) DEFAULT 0,
    solar_power_ge40kw_mwh DECIMAL(12,3) DEFAULT 0,
    solar_power_self_con_mwh DECIMAL(12,3) DEFAULT 0,
    total_solar_mwh DECIMAL(12,3) DEFAULT 0,
    
    -- Totals
    total_renewable_mwh DECIMAL(12,3) DEFAULT 0,
    total_production_mwh DECIMAL(12,3) DEFAULT 0,
    unknown_prod_mwh DECIMAL(12,3) DEFAULT 0,
    
    -- Consumption measures
    gross_consumption_mwh DECIMAL(12,3) DEFAULT 0,
    grid_loss_transmission_mwh DECIMAL(12,3) DEFAULT 0,
    grid_loss_interconnectors_mwh DECIMAL(12,3) DEFAULT 0,
    grid_loss_distribution_mwh DECIMAL(12,3) DEFAULT 0,
    total_grid_losses_mwh DECIMAL(12,3) DEFAULT 0,
    power_to_heat_mwh DECIMAL(12,3) DEFAULT 0,
    
    -- Exchange measures
    exchange_no_mwh DECIMAL(12,3) DEFAULT 0,
    exchange_se_mwh DECIMAL(12,3) DEFAULT 0,
    exchange_ge_mwh DECIMAL(12,3) DEFAULT 0,
    exchange_nl_mwh DECIMAL(12,3) DEFAULT 0,
    exchange_gb_mwh DECIMAL(12,3) DEFAULT 0,
    exchange_great_belt_mwh DECIMAL(12,3) DEFAULT 0,
    net_exchange_mwh DECIMAL(12,3) DEFAULT 0,
    
    -- Calculated percentages
    renewable_percentage DECIMAL(5,2) DEFAULT 0,
    wind_percentage DECIMAL(5,2) DEFAULT 0,
    solar_percentage DECIMAL(5,2) DEFAULT 0,
    grid_efficiency_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Categories
    renewable_category VARCHAR(30) NOT NULL,
    
    -- Flags
    is_peak_hour BOOLEAN NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    
    -- Timestamps
    timestamp_utc TIMESTAMP NOT NULL,
    timestamp_dk TIMESTAMP NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_production_date FOREIGN KEY (date_key) REFERENCES core.dim_date(date_key),
    CONSTRAINT fk_production_time FOREIGN KEY (time_key) REFERENCES core.dim_time(time_key),
    CONSTRAINT fk_production_price_area FOREIGN KEY (price_area_key) REFERENCES core.dim_price_area(price_area_key),
    
    -- Data quality constraints
    CONSTRAINT chk_renewable_percentage CHECK (renewable_percentage >= 0 AND renewable_percentage <= 100),
    CONSTRAINT chk_production_positive CHECK (total_production_mwh >= 0)
);

-- Electricity prices fact table
CREATE TABLE IF NOT EXISTS core.fact_electricity_prices (
    id BIGSERIAL PRIMARY KEY,
    date_key VARCHAR(8) NOT NULL,
    time_key VARCHAR(4) NOT NULL,
    price_area_key VARCHAR(10) NOT NULL,
    
    -- Price measures
    spot_price_dkk DECIMAL(12,2),
    spot_price_eur DECIMAL(12,2) NOT NULL,
    spot_price_dkk_calculated DECIMAL(12,2),
    exchange_rate_dkk_eur DECIMAL(8,4),
    
    -- Price analysis
    price_category VARCHAR(20) NOT NULL,
    price_change_eur DECIMAL(12,2),
    price_volatility_eur DECIMAL(12,2),
    price_change_percentage DECIMAL(8,2),
    
    -- Price indicators
    is_price_spike BOOLEAN NOT NULL,
    is_negative_price BOOLEAN NOT NULL,
    is_extreme_high_price BOOLEAN NOT NULL,
    is_very_low_price BOOLEAN NOT NULL,
    
    -- Flags
    is_peak_hour BOOLEAN NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    
    -- Timestamps
    timestamp_utc TIMESTAMP NOT NULL,
    timestamp_dk TIMESTAMP NOT NULL,
    loaded_at TIMESTAMP NOT NULL,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_prices_date FOREIGN KEY (date_key) REFERENCES core.dim_date(date_key),
    CONSTRAINT fk_prices_time FOREIGN KEY (time_key) REFERENCES core.dim_time(time_key),
    CONSTRAINT fk_prices_price_area FOREIGN KEY (price_area_key) REFERENCES core.dim_price_area(price_area_key),
    
    -- Data quality constraints
    CONSTRAINT chk_price_eur_range CHECK (spot_price_eur BETWEEN -1000 AND 5000)
);

-- Create indexes for fact tables (clustered on date for time-series performance)
CREATE INDEX IF NOT EXISTS idx_fact_co2_date_time_area ON core.fact_co2_emissions(date_key, time_key, price_area_key);
CREATE INDEX IF NOT EXISTS idx_fact_co2_date ON core.fact_co2_emissions(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_co2_timestamp ON core.fact_co2_emissions(timestamp_utc);
CREATE INDEX IF NOT EXISTS idx_fact_co2_area ON core.fact_co2_emissions(price_area_key);

CREATE INDEX IF NOT EXISTS idx_fact_production_date_time_area ON core.fact_energy_production(date_key, time_key, price_area_key);
CREATE INDEX IF NOT EXISTS idx_fact_production_date ON core.fact_energy_production(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_production_timestamp ON core.fact_energy_production(timestamp_utc);
CREATE INDEX IF NOT EXISTS idx_fact_production_area ON core.fact_energy_production(price_area_key);

CREATE INDEX IF NOT EXISTS idx_fact_prices_date_time_area ON core.fact_electricity_prices(date_key, time_key, price_area_key);
CREATE INDEX IF NOT EXISTS idx_fact_prices_date ON core.fact_electricity_prices(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_prices_timestamp ON core.fact_electricity_prices(timestamp_utc);
CREATE INDEX IF NOT EXISTS idx_fact_prices_area ON core.fact_electricity_prices(price_area_key);

-- Add table comments
COMMENT ON TABLE core.fact_co2_emissions IS 'Fact table for CO2 emissions with 5-minute granularity';
COMMENT ON TABLE core.fact_energy_production IS 'Fact table for energy production by source with hourly granularity';
COMMENT ON TABLE core.fact_electricity_prices IS 'Fact table for electricity prices with hourly granularity';

