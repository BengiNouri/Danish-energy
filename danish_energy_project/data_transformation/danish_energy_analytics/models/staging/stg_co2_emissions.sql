-- Staging model for CO2 emissions data
-- Cleans and standardizes raw CO2 emissions data from the API

{{ config(
    materialized='view',
    description='Cleaned CO2 emissions data with standardized timestamps and validated measures'
) }}

with source_data as (
    select
        -- Parse timestamps
        cast(minutes5utc as timestamp) as timestamp_utc,
        cast(minutes5dk as timestamp) as timestamp_dk,
        
        -- Geographic dimension
        trim(upper(pricearea)) as price_area_code,
        
        -- Measures
        cast(co2emission as decimal(10,2)) as co2_emission_g_kwh,
        
        -- Metadata
        current_timestamp as loaded_at
        
    from {{ source('raw_energy', 'co2_emissions') }}
    
    where 
        -- Data quality filters
        co2emission is not null
        and co2emission >= 0
        and co2emission <= {{ var('max_co2_intensity') }}
        and pricearea is not null
        and minutes5utc is not null
),

cleaned_data as (
    select
        *,
        
        -- Extract date and time components
        date(timestamp_utc) as date_utc,
        extract(hour from timestamp_utc) as hour_utc,
        extract(minute from timestamp_utc) as minute_utc,
        
        -- Business logic flags
        case 
            when extract(hour from timestamp_utc) between {{ var('peak_hours_start') }} and {{ var('peak_hours_end') }}
            then true 
            else false 
        end as is_peak_hour,
        
        case 
            when extract(dow from timestamp_utc) in (0, 6)  -- Sunday = 0, Saturday = 6
            then true 
            else false 
        end as is_weekend
        
    from source_data
)

select * from cleaned_data

