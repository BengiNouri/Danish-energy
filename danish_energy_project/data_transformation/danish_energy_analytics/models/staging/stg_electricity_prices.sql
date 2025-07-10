-- Staging model for electricity prices data
-- Cleans and standardizes raw electricity price data from the API

{{ config(
    materialized='view',
    description='Cleaned electricity price data with currency conversions and price validation'
) }}

with source_data as (
    select
        -- Parse timestamps
        cast(hourutc as timestamp) as timestamp_utc,
        cast(hourdk as timestamp) as timestamp_dk,
        
        -- Geographic dimension
        trim(upper(pricearea)) as price_area_code,
        
        -- Price measures
        cast(spotpricedkk as decimal(12,2)) as spot_price_dkk,
        cast(spotpriceeur as decimal(12,2)) as spot_price_eur,
        
        -- Metadata
        current_timestamp as loaded_at
        
    from {{ source('raw_energy', 'electricity_prices') }}
    
    where 
        -- Data quality filters
        hourutc is not null
        and pricearea is not null
        and spotpriceeur is not null  -- EUR price is more reliable
        and spotpriceeur between {{ var('min_price_dkk') }}/7.5 and {{ var('max_price_dkk') }}/7.5  -- Approximate DKK/EUR conversion
),

cleaned_data as (
    select
        *,
        
        -- Calculate exchange rate (DKK/EUR)
        case 
            when spot_price_eur != 0 and spot_price_dkk is not null
            then spot_price_dkk / spot_price_eur
            else 7.45  -- Default DKK/EUR rate
        end as exchange_rate_dkk_eur,
        
        -- Extract date and time components
        date(timestamp_utc) as date_utc,
        extract(hour from timestamp_utc) as hour_utc,
        
        -- Business logic flags
        case 
            when extract(hour from timestamp_utc) between {{ var('peak_hours_start') }} and {{ var('peak_hours_end') }}
            then true 
            else false 
        end as is_peak_hour,
        
        case 
            when extract(dow from timestamp_utc) in (0, 6)
            then true 
            else false 
        end as is_weekend,
        
        -- Price categories
        case 
            when spot_price_eur < 0 then 'Negative'
            when spot_price_eur < 25 then 'Low'
            when spot_price_eur < 75 then 'Medium'
            when spot_price_eur < 150 then 'High'
            else 'Very High'
        end as price_category
        
    from source_data
),

final_data as (
    select
        *,
        
        -- Fill missing DKK prices using EUR prices and exchange rate
        coalesce(
            spot_price_dkk,
            spot_price_eur * exchange_rate_dkk_eur
        ) as spot_price_dkk_calculated
        
    from cleaned_data
)

select * from final_data

