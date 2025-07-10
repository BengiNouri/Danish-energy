-- CO2 emissions fact table
-- Contains CO2 emissions data at 5-minute granularity

{{ config(
    materialized='table',
    description='Fact table for CO2 emissions with 5-minute granularity',
    indexes=[
      {'columns': ['date_key', 'time_key', 'price_area_key']},
      {'columns': ['date_key']},
      {'columns': ['price_area_key']},
    ]
) }}

with co2_emissions_with_keys as (
    select
        -- Dimension keys
        to_char(e.date_utc, 'YYYYMMDD') as date_key,
        lpad(e.hour_utc::text, 2, '0') || lpad(e.minute_utc::text, 2, '0') as time_key,
        'PA_' || e.price_area_code as price_area_key,
        
        -- Measures
        e.co2_emission_g_kwh,
        
        -- Calculated measures
        case 
            when e.co2_emission_g_kwh <= 50 then 'Very Low'
            when e.co2_emission_g_kwh <= 100 then 'Low'
            when e.co2_emission_g_kwh <= 200 then 'Medium'
            when e.co2_emission_g_kwh <= 400 then 'High'
            else 'Very High'
        end as emission_category,
        
        -- Flags
        e.is_peak_hour,
        e.is_weekend,
        
        -- Timestamps for reference
        e.timestamp_utc,
        e.timestamp_dk,
        
        -- Metadata
        e.loaded_at
        
    from {{ ref('stg_co2_emissions') }} e
),

fact_co2_emissions as (
    select
        -- Dimension keys
        date_key,
        time_key,
        price_area_key,
        
        -- Measures
        co2_emission_g_kwh,
        emission_category,
        
        -- Business flags
        is_peak_hour,
        is_weekend,
        
        -- Timestamps
        timestamp_utc,
        timestamp_dk,
        
        -- Metadata
        loaded_at,
        current_timestamp as processed_at
        
    from co2_emissions_with_keys
    
    -- Data quality filters
    where date_key is not null
      and time_key is not null
      and price_area_key is not null
      and co2_emission_g_kwh is not null
)

select * from fact_co2_emissions

