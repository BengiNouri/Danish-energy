-- Data transformation and ETL procedures for loading fact tables

-- Procedure to transform and load CO2 emissions fact data
CREATE OR REPLACE FUNCTION core.load_fact_co2_emissions()
RETURNS INTEGER AS $$
DECLARE
    rows_loaded INTEGER;
BEGIN
    -- Insert transformed data into fact table
    INSERT INTO core.fact_co2_emissions (
        date_key, time_key, price_area_key, co2_emission_g_kwh, emission_category,
        is_peak_hour, is_weekend, timestamp_utc, timestamp_dk, loaded_at
    )
    SELECT 
        TO_CHAR(r.minutes5utc, 'YYYYMMDD') as date_key,
        LPAD(EXTRACT(HOUR FROM r.minutes5utc)::TEXT, 2, '0') || 
        LPAD(EXTRACT(MINUTE FROM r.minutes5utc)::TEXT, 2, '0') as time_key,
        'PA_' || r.pricearea as price_area_key,
        r.co2emission as co2_emission_g_kwh,
        CASE 
            WHEN r.co2emission <= 50 THEN 'Very Low'
            WHEN r.co2emission <= 100 THEN 'Low'
            WHEN r.co2emission <= 200 THEN 'Medium'
            WHEN r.co2emission <= 400 THEN 'High'
            ELSE 'Very High'
        END as emission_category,
        CASE 
            WHEN EXTRACT(HOUR FROM r.minutes5utc) BETWEEN 17 AND 20 THEN TRUE 
            ELSE FALSE 
        END as is_peak_hour,
        CASE 
            WHEN EXTRACT(DOW FROM r.minutes5utc) IN (0, 6) THEN TRUE 
            ELSE FALSE 
        END as is_weekend,
        r.minutes5utc,
        r.minutes5dk,
        r.loaded_at
    FROM raw.co2_emissions r
    WHERE r.co2emission IS NOT NULL
      AND r.pricearea IN ('DK1', 'DK2')
      AND NOT EXISTS (
          SELECT 1 FROM core.fact_co2_emissions f 
          WHERE f.timestamp_utc = r.minutes5utc 
            AND f.price_area_key = 'PA_' || r.pricearea
      );
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    
    RAISE NOTICE 'Loaded % rows into fact_co2_emissions', rows_loaded;
    RETURN rows_loaded;
END;
$$ LANGUAGE plpgsql;

-- Procedure to transform and load energy production fact data
CREATE OR REPLACE FUNCTION core.load_fact_energy_production()
RETURNS INTEGER AS $$
DECLARE
    rows_loaded INTEGER;
BEGIN
    -- Insert transformed data into fact table
    INSERT INTO core.fact_energy_production (
        date_key, time_key, price_area_key,
        central_power_mwh, local_power_mwh, commercial_power_mwh, local_power_self_con_mwh,
        offshore_wind_lt100mw_mwh, offshore_wind_ge100mw_mwh, onshore_wind_lt50kw_mwh, onshore_wind_ge50kw_mwh,
        hydro_power_mwh, solar_power_lt10kw_mwh, solar_power_ge10lt40kw_mwh, solar_power_ge40kw_mwh, solar_power_self_con_mwh,
        total_renewable_mwh, total_production_mwh, unknown_prod_mwh,
        gross_consumption_mwh, grid_loss_transmission_mwh, grid_loss_interconnectors_mwh, grid_loss_distribution_mwh,
        power_to_heat_mwh, exchange_no_mwh, exchange_se_mwh, exchange_ge_mwh, exchange_nl_mwh, exchange_gb_mwh, exchange_great_belt_mwh,
        total_wind_mwh, total_solar_mwh, total_grid_losses_mwh, net_exchange_mwh,
        renewable_percentage, wind_percentage, solar_percentage, grid_efficiency_percentage, renewable_category,
        is_peak_hour, is_weekend, timestamp_utc, timestamp_dk, loaded_at
    )
    SELECT 
        TO_CHAR(r.hourutc, 'YYYYMMDD') as date_key,
        LPAD(EXTRACT(HOUR FROM r.hourutc)::TEXT, 2, '0') || '00' as time_key,
        'PA_' || r.pricearea as price_area_key,
        
        -- Production measures
        COALESCE(r.centralpowermwh, 0),
        COALESCE(r.localpowermwh, 0),
        COALESCE(r.commercialpowermwh, 0),
        COALESCE(r.localpowerselfconmwh, 0),
        
        -- Wind power
        COALESCE(r.offshorewindlt100mw_mwh, 0),
        COALESCE(r.offshorewindge100mw_mwh, 0),
        COALESCE(r.onshorewindlt50kw_mwh, 0),
        COALESCE(r.onshorewindge50kw_mwh, 0),
        
        -- Other renewables
        COALESCE(r.hydropowermwh, 0),
        COALESCE(r.solarpowerlt10kw_mwh, 0),
        COALESCE(r.solarpowerge10lt40kw_mwh, 0),
        COALESCE(r.solarpowerge40kw_mwh, 0),
        COALESCE(r.solarpowerselfconmwh, 0),
        
        -- Calculated totals
        (COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
         COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
         COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
         COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
         COALESCE(r.solarpowerselfconmwh, 0)) as total_renewable_mwh,
        
        (COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
         COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
         COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
         COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
         COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
         COALESCE(r.unknownprodmwh, 0)) as total_production_mwh,
        
        COALESCE(r.unknownprodmwh, 0),
        
        -- Consumption and grid
        COALESCE(r.grossconsumptionmwh, 0),
        COALESCE(r.gridlosstransmissionmwh, 0),
        COALESCE(r.gridlossinterconnectorsmwh, 0),
        COALESCE(r.gridlossdistributionmwh, 0),
        COALESCE(r.powertoheatmwh, 0),
        
        -- Exchange
        COALESCE(r.exchangeno_mwh, 0),
        COALESCE(r.exchangese_mwh, 0),
        COALESCE(r.exchangege_mwh, 0),
        COALESCE(r.exchangenl_mwh, 0),
        COALESCE(r.exchangegb_mwh, 0),
        COALESCE(r.exchangegreatbelt_mwh, 0),
        
        -- Additional calculated measures
        (COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
         COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0)) as total_wind_mwh,
        
        (COALESCE(r.solarpowerlt10kw_mwh, 0) + COALESCE(r.solarpowerge10lt40kw_mwh, 0) + 
         COALESCE(r.solarpowerge40kw_mwh, 0) + COALESCE(r.solarpowerselfconmwh, 0)) as total_solar_mwh,
        
        (COALESCE(r.gridlosstransmissionmwh, 0) + COALESCE(r.gridlossinterconnectorsmwh, 0) + 
         COALESCE(r.gridlossdistributionmwh, 0)) as total_grid_losses_mwh,
        
        (COALESCE(r.exchangeno_mwh, 0) + COALESCE(r.exchangese_mwh, 0) + COALESCE(r.exchangege_mwh, 0) + 
         COALESCE(r.exchangenl_mwh, 0) + COALESCE(r.exchangegb_mwh, 0) + COALESCE(r.exchangegreatbelt_mwh, 0)) as net_exchange_mwh,
        
        -- Percentages
        CASE 
            WHEN (COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                  COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.unknownprodmwh, 0)) > 0 
            THEN ((COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                   COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                   COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                   COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                   COALESCE(r.solarpowerselfconmwh, 0)) / 
                  (COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                   COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                   COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                   COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                   COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                   COALESCE(r.unknownprodmwh, 0))) * 100
            ELSE 0 
        END as renewable_percentage,
        
        CASE 
            WHEN (COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                  COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.unknownprodmwh, 0)) > 0 
            THEN ((COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                   COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0)) / 
                  (COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                   COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                   COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                   COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                   COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                   COALESCE(r.unknownprodmwh, 0))) * 100
            ELSE 0 
        END as wind_percentage,
        
        CASE 
            WHEN (COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                  COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.unknownprodmwh, 0)) > 0 
            THEN ((COALESCE(r.solarpowerlt10kw_mwh, 0) + COALESCE(r.solarpowerge10lt40kw_mwh, 0) + 
                   COALESCE(r.solarpowerge40kw_mwh, 0) + COALESCE(r.solarpowerselfconmwh, 0)) / 
                  (COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                   COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                   COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                   COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                   COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                   COALESCE(r.unknownprodmwh, 0))) * 100
            ELSE 0 
        END as solar_percentage,
        
        CASE 
            WHEN COALESCE(r.grossconsumptionmwh, 0) > 0 
            THEN ((COALESCE(r.grossconsumptionmwh, 0) - (COALESCE(r.gridlosstransmissionmwh, 0) + COALESCE(r.gridlossinterconnectorsmwh, 0) + 
                   COALESCE(r.gridlossdistributionmwh, 0))) / COALESCE(r.grossconsumptionmwh, 0)) * 100
            ELSE 0 
        END as grid_efficiency_percentage,
        
        -- Renewable category
        CASE 
            WHEN (COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.solarpowerselfconmwh, 0)) / NULLIF((COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                  COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.unknownprodmwh, 0)), 0) >= 0.8 THEN 'Very High Renewable'
            WHEN (COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.solarpowerselfconmwh, 0)) / NULLIF((COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                  COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.unknownprodmwh, 0)), 0) >= 0.6 THEN 'High Renewable'
            WHEN (COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.solarpowerselfconmwh, 0)) / NULLIF((COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                  COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.unknownprodmwh, 0)), 0) >= 0.4 THEN 'Medium Renewable'
            WHEN (COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.solarpowerselfconmwh, 0)) / NULLIF((COALESCE(r.centralpowermwh, 0) + COALESCE(r.localpowermwh, 0) + COALESCE(r.commercialpowermwh, 0) +
                  COALESCE(r.offshorewindlt100mw_mwh, 0) + COALESCE(r.offshorewindge100mw_mwh, 0) + 
                  COALESCE(r.onshorewindlt50kw_mwh, 0) + COALESCE(r.onshorewindge50kw_mwh, 0) +
                  COALESCE(r.hydropowermwh, 0) + COALESCE(r.solarpowerlt10kw_mwh, 0) + 
                  COALESCE(r.solarpowerge10lt40kw_mwh, 0) + COALESCE(r.solarpowerge40kw_mwh, 0) + 
                  COALESCE(r.unknownprodmwh, 0)), 0) >= 0.2 THEN 'Low Renewable'
            ELSE 'Very Low Renewable'
        END as renewable_category,
        
        -- Flags
        CASE 
            WHEN EXTRACT(HOUR FROM r.hourutc) BETWEEN 17 AND 20 THEN TRUE 
            ELSE FALSE 
        END as is_peak_hour,
        CASE 
            WHEN EXTRACT(DOW FROM r.hourutc) IN (0, 6) THEN TRUE 
            ELSE FALSE 
        END as is_weekend,
        
        r.hourutc,
        r.hourdk,
        r.loaded_at
    FROM raw.renewable_energy r
    WHERE r.pricearea IN ('DK1', 'DK2')
      AND NOT EXISTS (
          SELECT 1 FROM core.fact_energy_production f 
          WHERE f.timestamp_utc = r.hourutc 
            AND f.price_area_key = 'PA_' || r.pricearea
      );
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    
    RAISE NOTICE 'Loaded % rows into fact_energy_production', rows_loaded;
    RETURN rows_loaded;
END;
$$ LANGUAGE plpgsql;

-- Procedure to transform and load electricity prices fact data
CREATE OR REPLACE FUNCTION core.load_fact_electricity_prices()
RETURNS INTEGER AS $$
DECLARE
    rows_loaded INTEGER;
BEGIN
    -- Insert transformed data into fact table
    INSERT INTO core.fact_electricity_prices (
        date_key, time_key, price_area_key, spot_price_dkk, spot_price_eur, spot_price_dkk_calculated,
        exchange_rate_dkk_eur, price_category, price_change_eur, price_volatility_eur, price_change_percentage,
        is_price_spike, is_negative_price, is_extreme_high_price, is_very_low_price,
        is_peak_hour, is_weekend, timestamp_utc, timestamp_dk, loaded_at
    )
    WITH price_with_changes AS (
        SELECT 
            r.*,
            LAG(r.spotpriceeur) OVER (PARTITION BY r.pricearea ORDER BY r.hourutc) as prev_price_eur
        FROM raw.electricity_prices r
        WHERE r.pricearea IN ('DK1', 'DK2')
          AND r.spotpriceeur IS NOT NULL
    )
    SELECT 
        TO_CHAR(p.hourutc, 'YYYYMMDD') as date_key,
        LPAD(EXTRACT(HOUR FROM p.hourutc)::TEXT, 2, '0') || '00' as time_key,
        'PA_' || p.pricearea as price_area_key,
        p.spotpricedkk,
        p.spotpriceeur,
        COALESCE(p.spotpricedkk, p.spotpriceeur * 7.45) as spot_price_dkk_calculated,
        CASE 
            WHEN p.spotpriceeur != 0 AND p.spotpricedkk IS NOT NULL
            THEN p.spotpricedkk / p.spotpriceeur
            ELSE 7.45
        END as exchange_rate_dkk_eur,
        CASE 
            WHEN p.spotpriceeur < 0 THEN 'Negative'
            WHEN p.spotpriceeur < 25 THEN 'Low'
            WHEN p.spotpriceeur < 75 THEN 'Medium'
            WHEN p.spotpriceeur < 150 THEN 'High'
            ELSE 'Very High'
        END as price_category,
        COALESCE(p.spotpriceeur - p.prev_price_eur, 0) as price_change_eur,
        ABS(COALESCE(p.spotpriceeur - p.prev_price_eur, 0)) as price_volatility_eur,
        CASE 
            WHEN p.prev_price_eur > 0 
            THEN ((p.spotpriceeur - p.prev_price_eur) / p.prev_price_eur) * 100
            ELSE 0 
        END as price_change_percentage,
        CASE 
            WHEN ABS(COALESCE(p.spotpriceeur - p.prev_price_eur, 0)) > 50 THEN TRUE
            ELSE FALSE 
        END as is_price_spike,
        CASE 
            WHEN p.spotpriceeur < 0 THEN TRUE
            ELSE FALSE 
        END as is_negative_price,
        CASE 
            WHEN p.spotpriceeur > 200 THEN TRUE
            ELSE FALSE 
        END as is_extreme_high_price,
        CASE 
            WHEN p.spotpriceeur < 10 THEN TRUE
            ELSE FALSE 
        END as is_very_low_price,
        CASE 
            WHEN EXTRACT(HOUR FROM p.hourutc) BETWEEN 17 AND 20 THEN TRUE 
            ELSE FALSE 
        END as is_peak_hour,
        CASE 
            WHEN EXTRACT(DOW FROM p.hourutc) IN (0, 6) THEN TRUE 
            ELSE FALSE 
        END as is_weekend,
        p.hourutc,
        p.hourdk,
        p.loaded_at
    FROM price_with_changes p
    WHERE NOT EXISTS (
        SELECT 1 FROM core.fact_electricity_prices f 
        WHERE f.timestamp_utc = p.hourutc 
          AND f.price_area_key = 'PA_' || p.pricearea
    );
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    
    RAISE NOTICE 'Loaded % rows into fact_electricity_prices', rows_loaded;
    RETURN rows_loaded;
END;
$$ LANGUAGE plpgsql;

-- Master ETL procedure to load all fact tables
CREATE OR REPLACE FUNCTION core.run_etl_pipeline()
RETURNS TEXT AS $$
DECLARE
    co2_rows INTEGER;
    production_rows INTEGER;
    prices_rows INTEGER;
    result_text TEXT;
BEGIN
    -- Load fact tables in sequence
    SELECT core.load_fact_co2_emissions() INTO co2_rows;
    SELECT core.load_fact_energy_production() INTO production_rows;
    SELECT core.load_fact_electricity_prices() INTO prices_rows;
    
    -- Create result summary
    result_text := format('ETL Pipeline completed successfully:
- CO2 emissions: %s rows loaded
- Energy production: %s rows loaded  
- Electricity prices: %s rows loaded
Total: %s rows loaded', 
        co2_rows, production_rows, prices_rows, 
        co2_rows + production_rows + prices_rows);
    
    RAISE NOTICE '%', result_text;
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Add comments to ETL functions
COMMENT ON FUNCTION core.load_fact_co2_emissions() IS 'Transform and load CO2 emissions data into fact table';
COMMENT ON FUNCTION core.load_fact_energy_production() IS 'Transform and load energy production data into fact table';
COMMENT ON FUNCTION core.load_fact_electricity_prices() IS 'Transform and load electricity prices data into fact table';
COMMENT ON FUNCTION core.run_etl_pipeline() IS 'Master ETL procedure to load all fact tables';

