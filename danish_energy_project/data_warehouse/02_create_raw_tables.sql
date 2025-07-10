-- Raw data tables for Danish Energy Analytics
-- These tables store the raw data from external APIs and sources

-- Raw CO2 emissions data
CREATE TABLE IF NOT EXISTS raw.co2_emissions (
    id SERIAL PRIMARY KEY,
    minutes5utc TIMESTAMP NOT NULL,
    minutes5dk TIMESTAMP NOT NULL,
    pricearea VARCHAR(10) NOT NULL,
    co2emission DECIMAL(10,2),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file VARCHAR(255),
    
    -- Constraints
    CONSTRAINT chk_co2_emission_positive CHECK (co2emission >= 0),
    CONSTRAINT chk_co2_emission_reasonable CHECK (co2emission <= 1000)
);

-- Raw renewable energy production data
CREATE TABLE IF NOT EXISTS raw.renewable_energy (
    id SERIAL PRIMARY KEY,
    hourutc TIMESTAMP NOT NULL,
    hourdk TIMESTAMP NOT NULL,
    pricearea VARCHAR(10) NOT NULL,
    centralpowermwh DECIMAL(12,3),
    localpowermwh DECIMAL(12,3),
    commercialpowermwh DECIMAL(12,3),
    localpowerselfconmwh DECIMAL(12,3),
    offshorewindlt100mw_mwh DECIMAL(12,3),
    offshorewindge100mw_mwh DECIMAL(12,3),
    onshorewindlt50kw_mwh DECIMAL(12,3),
    onshorewindge50kw_mwh DECIMAL(12,3),
    hydropowermwh DECIMAL(12,3),
    solarpowerlt10kw_mwh DECIMAL(12,3),
    solarpowerge10lt40kw_mwh DECIMAL(12,3),
    solarpowerge40kw_mwh DECIMAL(12,3),
    solarpowerselfconmwh DECIMAL(12,3),
    unknownprodmwh DECIMAL(12,3),
    exchangeno_mwh DECIMAL(12,3),
    exchangese_mwh DECIMAL(12,3),
    exchangege_mwh DECIMAL(12,3),
    exchangenl_mwh DECIMAL(12,3),
    exchangegb_mwh DECIMAL(12,3),
    exchangegreatbelt_mwh DECIMAL(12,3),
    grossconsumptionmwh DECIMAL(12,3),
    gridlosstransmissionmwh DECIMAL(12,3),
    gridlossinterconnectorsmwh DECIMAL(12,3),
    gridlossdistributionmwh DECIMAL(12,3),
    powertoheatmwh DECIMAL(12,3),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file VARCHAR(255),
    
    -- Constraints
    CONSTRAINT chk_gross_consumption_positive CHECK (grossconsumptionmwh >= 0)
);

-- Raw electricity prices data
CREATE TABLE IF NOT EXISTS raw.electricity_prices (
    id SERIAL PRIMARY KEY,
    hourutc TIMESTAMP NOT NULL,
    hourdk TIMESTAMP NOT NULL,
    pricearea VARCHAR(10) NOT NULL,
    spotpricedkk DECIMAL(12,2),
    spotpriceeur DECIMAL(12,2),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file VARCHAR(255),
    
    -- Constraints
    CONSTRAINT chk_price_eur_reasonable CHECK (spotpriceeur BETWEEN -1000 AND 5000)
);

-- Create indexes for raw tables
CREATE INDEX IF NOT EXISTS idx_co2_emissions_timestamp ON raw.co2_emissions(minutes5utc);
CREATE INDEX IF NOT EXISTS idx_co2_emissions_pricearea ON raw.co2_emissions(pricearea);
CREATE INDEX IF NOT EXISTS idx_co2_emissions_composite ON raw.co2_emissions(minutes5utc, pricearea);

CREATE INDEX IF NOT EXISTS idx_renewable_energy_timestamp ON raw.renewable_energy(hourutc);
CREATE INDEX IF NOT EXISTS idx_renewable_energy_pricearea ON raw.renewable_energy(pricearea);
CREATE INDEX IF NOT EXISTS idx_renewable_energy_composite ON raw.renewable_energy(hourutc, pricearea);

CREATE INDEX IF NOT EXISTS idx_electricity_prices_timestamp ON raw.electricity_prices(hourutc);
CREATE INDEX IF NOT EXISTS idx_electricity_prices_pricearea ON raw.electricity_prices(pricearea);
CREATE INDEX IF NOT EXISTS idx_electricity_prices_composite ON raw.electricity_prices(hourutc, pricearea);

-- Add comments to tables
COMMENT ON TABLE raw.co2_emissions IS 'Raw CO2 emissions data from Energi Data Service API';
COMMENT ON TABLE raw.renewable_energy IS 'Raw renewable energy production and consumption data';
COMMENT ON TABLE raw.electricity_prices IS 'Raw electricity spot price data from Nordic markets';

-- Add comments to key columns
COMMENT ON COLUMN raw.co2_emissions.co2emission IS 'CO2 emissions in grams per kWh';
COMMENT ON COLUMN raw.renewable_energy.grossconsumptionmwh IS 'Total gross electricity consumption in MWh';
COMMENT ON COLUMN raw.electricity_prices.spotpriceeur IS 'Spot electricity price in EUR per MWh';

