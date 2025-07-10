-- Core dimension tables for the star schema

-- Date dimension table
CREATE TABLE IF NOT EXISTS core.dim_date (
    date_key VARCHAR(8) PRIMARY KEY,
    date_actual DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    quarter_name VARCHAR(2) NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_name_short VARCHAR(3) NOT NULL,
    week_of_year INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    day_name_short VARCHAR(3) NOT NULL,
    day_of_year INTEGER NOT NULL,
    day_of_month INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_weekday BOOLEAN NOT NULL,
    season VARCHAR(10) NOT NULL,
    is_danish_holiday BOOLEAN NOT NULL,
    date_last_year DATE NOT NULL,
    date_last_month DATE NOT NULL,
    date_last_week DATE NOT NULL,
    date_yesterday DATE NOT NULL,
    fiscal_year INTEGER NOT NULL,
    iso_year INTEGER NOT NULL,
    iso_week INTEGER NOT NULL,
    date_iso VARCHAR(10) NOT NULL,
    date_european VARCHAR(10) NOT NULL,
    date_american VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Time dimension table
CREATE TABLE IF NOT EXISTS core.dim_time (
    time_key VARCHAR(4) PRIMARY KEY,
    hour INTEGER NOT NULL,
    minute INTEGER NOT NULL,
    time_24hr VARCHAR(5) NOT NULL,
    time_12hr VARCHAR(8) NOT NULL,
    time_of_day VARCHAR(20) NOT NULL,
    energy_period VARCHAR(20) NOT NULL,
    is_peak_hour BOOLEAN NOT NULL,
    is_business_hour BOOLEAN NOT NULL,
    is_night_hour BOOLEAN NOT NULL,
    load_period VARCHAR(20) NOT NULL,
    is_solar_hours BOOLEAN NOT NULL,
    solar_potential VARCHAR(20) NOT NULL,
    is_hour_start BOOLEAN NOT NULL,
    is_quarter_hour BOOLEAN NOT NULL,
    minutes_from_midnight INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_hour_range CHECK (hour BETWEEN 0 AND 23),
    CONSTRAINT chk_minute_range CHECK (minute BETWEEN 0 AND 59)
);

-- Price area dimension table
CREATE TABLE IF NOT EXISTS core.dim_price_area (
    price_area_key VARCHAR(10) PRIMARY KEY,
    price_area_code VARCHAR(10) NOT NULL UNIQUE,
    price_area_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL,
    is_danish_area BOOLEAN NOT NULL,
    is_nordic_area BOOLEAN NOT NULL,
    is_system_price BOOLEAN NOT NULL,
    grid_operator VARCHAR(100) NOT NULL,
    time_zone VARCHAR(10) NOT NULL,
    renewable_profile VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for dimension tables
CREATE INDEX IF NOT EXISTS idx_dim_date_actual ON core.dim_date(date_actual);
CREATE INDEX IF NOT EXISTS idx_dim_date_year_month ON core.dim_date(year, month);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_weekend ON core.dim_date(is_weekend);

CREATE INDEX IF NOT EXISTS idx_dim_time_hour_minute ON core.dim_time(hour, minute);
CREATE INDEX IF NOT EXISTS idx_dim_time_is_peak ON core.dim_time(is_peak_hour);

CREATE INDEX IF NOT EXISTS idx_dim_price_area_code ON core.dim_price_area(price_area_code);
CREATE INDEX IF NOT EXISTS idx_dim_price_area_country ON core.dim_price_area(country);
CREATE INDEX IF NOT EXISTS idx_dim_price_area_is_danish ON core.dim_price_area(is_danish_area);

-- Add comments
COMMENT ON TABLE core.dim_date IS 'Date dimension with business calendar attributes';
COMMENT ON TABLE core.dim_time IS 'Time dimension with hour and minute granularity';
COMMENT ON TABLE core.dim_price_area IS 'Price area dimension with geographic and market attributes';

