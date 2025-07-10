-- Data loading procedures and functions for the Danish Energy Analytics warehouse

-- Function to load raw CO2 emissions data from CSV
CREATE OR REPLACE FUNCTION raw.load_co2_emissions_from_csv(file_path TEXT)
RETURNS INTEGER AS $$
DECLARE
    rows_loaded INTEGER;
BEGIN
    -- Create temporary table for staging
    CREATE TEMP TABLE temp_co2_emissions (
        minutes5utc TEXT,
        minutes5dk TEXT,
        pricearea TEXT,
        co2emission TEXT
    );
    
    -- Load data from CSV
    EXECUTE format('COPY temp_co2_emissions FROM %L WITH CSV HEADER', file_path);
    
    -- Insert into raw table with data type conversions and validation
    INSERT INTO raw.co2_emissions (
        minutes5utc, minutes5dk, pricearea, co2emission, source_file
    )
    SELECT 
        minutes5utc::TIMESTAMP,
        minutes5dk::TIMESTAMP,
        UPPER(TRIM(pricearea)),
        CASE 
            WHEN co2emission ~ '^[0-9]+\.?[0-9]*$' THEN co2emission::DECIMAL(10,2)
            ELSE NULL 
        END,
        file_path
    FROM temp_co2_emissions
    WHERE minutes5utc IS NOT NULL 
      AND pricearea IS NOT NULL
      AND co2emission ~ '^[0-9]+\.?[0-9]*$'
      AND co2emission::DECIMAL(10,2) BETWEEN 0 AND 1000;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    
    -- Clean up
    DROP TABLE temp_co2_emissions;
    
    RETURN rows_loaded;
END;
$$ LANGUAGE plpgsql;

-- Function to load raw renewable energy data from CSV
CREATE OR REPLACE FUNCTION raw.load_renewable_energy_from_csv(file_path TEXT)
RETURNS INTEGER AS $$
DECLARE
    rows_loaded INTEGER;
BEGIN
    -- Create temporary table for staging
    CREATE TEMP TABLE temp_renewable_energy (
        hourutc TEXT,
        hourdk TEXT,
        pricearea TEXT,
        centralpowermwh TEXT,
        localpowermwh TEXT,
        commercialpowermwh TEXT,
        localpowerselfconmwh TEXT,
        offshorewindlt100mw_mwh TEXT,
        offshorewindge100mw_mwh TEXT,
        onshorewindlt50kw_mwh TEXT,
        onshorewindge50kw_mwh TEXT,
        hydropowermwh TEXT,
        solarpowerlt10kw_mwh TEXT,
        solarpowerge10lt40kw_mwh TEXT,
        solarpowerge40kw_mwh TEXT,
        solarpowerselfconmwh TEXT,
        unknownprodmwh TEXT,
        exchangeno_mwh TEXT,
        exchangese_mwh TEXT,
        exchangege_mwh TEXT,
        exchangenl_mwh TEXT,
        exchangegb_mwh TEXT,
        exchangegreatbelt_mwh TEXT,
        grossconsumptionmwh TEXT,
        gridlosstransmissionmwh TEXT,
        gridlossinterconnectorsmwh TEXT,
        gridlossdistributionmwh TEXT,
        powertoheatmwh TEXT
    );
    
    -- Load data from CSV
    EXECUTE format('COPY temp_renewable_energy FROM %L WITH CSV HEADER', file_path);
    
    -- Insert into raw table with data type conversions
    INSERT INTO raw.renewable_energy (
        hourutc, hourdk, pricearea,
        centralpowermwh, localpowermwh, commercialpowermwh, localpowerselfconmwh,
        offshorewindlt100mw_mwh, offshorewindge100mw_mwh, onshorewindlt50kw_mwh, onshorewindge50kw_mwh,
        hydropowermwh, solarpowerlt10kw_mwh, solarpowerge10lt40kw_mwh, solarpowerge40kw_mwh, solarpowerselfconmwh,
        unknownprodmwh, exchangeno_mwh, exchangese_mwh, exchangege_mwh, exchangenl_mwh, exchangegb_mwh, exchangegreatbelt_mwh,
        grossconsumptionmwh, gridlosstransmissionmwh, gridlossinterconnectorsmwh, gridlossdistributionmwh, powertoheatmwh,
        source_file
    )
    SELECT 
        hourutc::TIMESTAMP,
        hourdk::TIMESTAMP,
        UPPER(TRIM(pricearea)),
        CASE WHEN centralpowermwh ~ '^-?[0-9]+\.?[0-9]*$' THEN centralpowermwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN localpowermwh ~ '^-?[0-9]+\.?[0-9]*$' THEN localpowermwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN commercialpowermwh ~ '^-?[0-9]+\.?[0-9]*$' THEN commercialpowermwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN localpowerselfconmwh ~ '^-?[0-9]+\.?[0-9]*$' THEN localpowerselfconmwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN offshorewindlt100mw_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN offshorewindlt100mw_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN offshorewindge100mw_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN offshorewindge100mw_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN onshorewindlt50kw_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN onshorewindlt50kw_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN onshorewindge50kw_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN onshorewindge50kw_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN hydropowermwh ~ '^-?[0-9]+\.?[0-9]*$' THEN hydropowermwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN solarpowerlt10kw_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN solarpowerlt10kw_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN solarpowerge10lt40kw_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN solarpowerge10lt40kw_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN solarpowerge40kw_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN solarpowerge40kw_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN solarpowerselfconmwh ~ '^-?[0-9]+\.?[0-9]*$' THEN solarpowerselfconmwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN unknownprodmwh ~ '^-?[0-9]+\.?[0-9]*$' THEN unknownprodmwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN exchangeno_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN exchangeno_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN exchangese_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN exchangese_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN exchangege_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN exchangege_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN exchangenl_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN exchangenl_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN exchangegb_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN exchangegb_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN exchangegreatbelt_mwh ~ '^-?[0-9]+\.?[0-9]*$' THEN exchangegreatbelt_mwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN grossconsumptionmwh ~ '^-?[0-9]+\.?[0-9]*$' THEN grossconsumptionmwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN gridlosstransmissionmwh ~ '^-?[0-9]+\.?[0-9]*$' THEN gridlosstransmissionmwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN gridlossinterconnectorsmwh ~ '^-?[0-9]+\.?[0-9]*$' THEN gridlossinterconnectorsmwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN gridlossdistributionmwh ~ '^-?[0-9]+\.?[0-9]*$' THEN gridlossdistributionmwh::DECIMAL(12,3) ELSE NULL END,
        CASE WHEN powertoheatmwh ~ '^-?[0-9]+\.?[0-9]*$' THEN powertoheatmwh::DECIMAL(12,3) ELSE NULL END,
        file_path
    FROM temp_renewable_energy
    WHERE hourutc IS NOT NULL 
      AND pricearea IS NOT NULL;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    
    -- Clean up
    DROP TABLE temp_renewable_energy;
    
    RETURN rows_loaded;
END;
$$ LANGUAGE plpgsql;

-- Function to load raw electricity prices data from CSV
CREATE OR REPLACE FUNCTION raw.load_electricity_prices_from_csv(file_path TEXT)
RETURNS INTEGER AS $$
DECLARE
    rows_loaded INTEGER;
BEGIN
    -- Create temporary table for staging
    CREATE TEMP TABLE temp_electricity_prices (
        hourutc TEXT,
        hourdk TEXT,
        pricearea TEXT,
        spotpricedkk TEXT,
        spotpriceeur TEXT
    );
    
    -- Load data from CSV
    EXECUTE format('COPY temp_electricity_prices FROM %L WITH CSV HEADER', file_path);
    
    -- Insert into raw table with data type conversions
    INSERT INTO raw.electricity_prices (
        hourutc, hourdk, pricearea, spotpricedkk, spotpriceeur, source_file
    )
    SELECT 
        hourutc::TIMESTAMP,
        hourdk::TIMESTAMP,
        UPPER(TRIM(pricearea)),
        CASE WHEN spotpricedkk ~ '^-?[0-9]+\.?[0-9]*$' THEN spotpricedkk::DECIMAL(12,2) ELSE NULL END,
        CASE WHEN spotpriceeur ~ '^-?[0-9]+\.?[0-9]*$' THEN spotpriceeur::DECIMAL(12,2) ELSE NULL END,
        file_path
    FROM temp_electricity_prices
    WHERE hourutc IS NOT NULL 
      AND pricearea IS NOT NULL
      AND spotpriceeur IS NOT NULL
      AND spotpriceeur ~ '^-?[0-9]+\.?[0-9]*$'
      AND spotpriceeur::DECIMAL(12,2) BETWEEN -1000 AND 5000;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    
    -- Clean up
    DROP TABLE temp_electricity_prices;
    
    RETURN rows_loaded;
END;
$$ LANGUAGE plpgsql;

-- Procedure to populate dimension tables
CREATE OR REPLACE FUNCTION core.populate_dimension_tables()
RETURNS VOID AS $$
BEGIN
    -- Populate date dimension (2020-2024)
    INSERT INTO core.dim_date (
        date_key, date_actual, year, quarter, quarter_name, month, month_name, month_name_short,
        week_of_year, day_of_week, day_name, day_name_short, day_of_year, day_of_month,
        is_weekend, is_weekday, season, is_danish_holiday,
        date_last_year, date_last_month, date_last_week, date_yesterday,
        fiscal_year, iso_year, iso_week, date_iso, date_european, date_american
    )
    SELECT 
        TO_CHAR(d, 'YYYYMMDD') as date_key,
        d as date_actual,
        EXTRACT(YEAR FROM d) as year,
        EXTRACT(QUARTER FROM d) as quarter,
        'Q' || EXTRACT(QUARTER FROM d) as quarter_name,
        EXTRACT(MONTH FROM d) as month,
        TO_CHAR(d, 'Month') as month_name,
        TO_CHAR(d, 'Mon') as month_name_short,
        EXTRACT(WEEK FROM d) as week_of_year,
        EXTRACT(DOW FROM d) as day_of_week,
        TO_CHAR(d, 'Day') as day_name,
        TO_CHAR(d, 'Dy') as day_name_short,
        EXTRACT(DOY FROM d) as day_of_year,
        EXTRACT(DAY FROM d) as day_of_month,
        CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN TRUE ELSE FALSE END as is_weekend,
        CASE WHEN EXTRACT(DOW FROM d) BETWEEN 1 AND 5 THEN TRUE ELSE FALSE END as is_weekday,
        CASE 
            WHEN EXTRACT(MONTH FROM d) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM d) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM d) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM d) IN (9, 10, 11) THEN 'Autumn'
        END as season,
        CASE 
            WHEN EXTRACT(MONTH FROM d) = 1 AND EXTRACT(DAY FROM d) = 1 THEN TRUE
            WHEN EXTRACT(MONTH FROM d) = 12 AND EXTRACT(DAY FROM d) = 25 THEN TRUE
            WHEN EXTRACT(MONTH FROM d) = 12 AND EXTRACT(DAY FROM d) = 26 THEN TRUE
            WHEN EXTRACT(MONTH FROM d) = 6 AND EXTRACT(DAY FROM d) = 5 THEN TRUE
            ELSE FALSE
        END as is_danish_holiday,
        d - INTERVAL '1 year' as date_last_year,
        d - INTERVAL '1 month' as date_last_month,
        d - INTERVAL '1 week' as date_last_week,
        d - INTERVAL '1 day' as date_yesterday,
        EXTRACT(YEAR FROM d) as fiscal_year,
        EXTRACT(ISOYEAR FROM d) as iso_year,
        EXTRACT(WEEK FROM d) as iso_week,
        TO_CHAR(d, 'YYYY-MM-DD') as date_iso,
        TO_CHAR(d, 'DD/MM/YYYY') as date_european,
        TO_CHAR(d, 'MM/DD/YYYY') as date_american
    FROM generate_series('2020-01-01'::DATE, '2024-12-31'::DATE, '1 day'::INTERVAL) d
    ON CONFLICT (date_key) DO NOTHING;
    
    -- Populate time dimension
    INSERT INTO core.dim_time (
        time_key, hour, minute, time_24hr, time_12hr, time_of_day, energy_period,
        is_peak_hour, is_business_hour, is_night_hour, load_period,
        is_solar_hours, solar_potential, is_hour_start, is_quarter_hour, minutes_from_midnight
    )
    SELECT 
        LPAD(h::TEXT, 2, '0') || LPAD(m::TEXT, 2, '0') as time_key,
        h as hour,
        m as minute,
        LPAD(h::TEXT, 2, '0') || ':' || LPAD(m::TEXT, 2, '0') as time_24hr,
        CASE 
            WHEN h = 0 THEN '12:' || LPAD(m::TEXT, 2, '0') || ' AM'
            WHEN h < 12 THEN LPAD(h::TEXT, 2, '0') || ':' || LPAD(m::TEXT, 2, '0') || ' AM'
            WHEN h = 12 THEN '12:' || LPAD(m::TEXT, 2, '0') || ' PM'
            ELSE LPAD((h - 12)::TEXT, 2, '0') || ':' || LPAD(m::TEXT, 2, '0') || ' PM'
        END as time_12hr,
        CASE 
            WHEN h BETWEEN 0 AND 5 THEN 'Night'
            WHEN h BETWEEN 6 AND 11 THEN 'Morning'
            WHEN h BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN h BETWEEN 18 AND 23 THEN 'Evening'
        END as time_of_day,
        CASE 
            WHEN h BETWEEN 6 AND 9 THEN 'Morning Peak'
            WHEN h BETWEEN 17 AND 20 THEN 'Evening Peak'
            WHEN h BETWEEN 10 AND 16 THEN 'Daytime'
            WHEN h BETWEEN 21 AND 23 THEN 'Evening Off-Peak'
            ELSE 'Night'
        END as energy_period,
        CASE WHEN h BETWEEN 17 AND 20 THEN TRUE ELSE FALSE END as is_peak_hour,
        CASE WHEN h BETWEEN 8 AND 18 THEN TRUE ELSE FALSE END as is_business_hour,
        CASE WHEN h BETWEEN 22 AND 23 OR h BETWEEN 0 AND 6 THEN TRUE ELSE FALSE END as is_night_hour,
        CASE 
            WHEN h BETWEEN 0 AND 5 THEN 'Base Load'
            WHEN h BETWEEN 6 AND 8 THEN 'Morning Ramp'
            WHEN h BETWEEN 9 AND 16 THEN 'Day Load'
            WHEN h BETWEEN 17 AND 20 THEN 'Peak Load'
            WHEN h BETWEEN 21 AND 23 THEN 'Evening Ramp'
        END as load_period,
        CASE WHEN h BETWEEN 6 AND 18 THEN TRUE ELSE FALSE END as is_solar_hours,
        CASE 
            WHEN h BETWEEN 10 AND 14 THEN 'Peak Solar'
            WHEN h BETWEEN 8 AND 9 OR h BETWEEN 15 AND 17 THEN 'Good Solar'
            WHEN h BETWEEN 6 AND 7 OR h BETWEEN 18 AND 19 THEN 'Low Solar'
            ELSE 'No Solar'
        END as solar_potential,
        CASE WHEN m = 0 THEN TRUE ELSE FALSE END as is_hour_start,
        CASE WHEN m IN (0, 15, 30, 45) THEN TRUE ELSE FALSE END as is_quarter_hour,
        h * 60 + m as minutes_from_midnight
    FROM generate_series(0, 23) h
    CROSS JOIN generate_series(0, 55, 5) m
    ON CONFLICT (time_key) DO NOTHING;
    
    RAISE NOTICE 'Dimension tables populated successfully';
END;
$$ LANGUAGE plpgsql;

-- Add comments to functions
COMMENT ON FUNCTION raw.load_co2_emissions_from_csv(TEXT) IS 'Load CO2 emissions data from CSV file with validation';
COMMENT ON FUNCTION raw.load_renewable_energy_from_csv(TEXT) IS 'Load renewable energy data from CSV file with validation';
COMMENT ON FUNCTION raw.load_electricity_prices_from_csv(TEXT) IS 'Load electricity prices data from CSV file with validation';
COMMENT ON FUNCTION core.populate_dimension_tables() IS 'Populate all dimension tables with reference data';

