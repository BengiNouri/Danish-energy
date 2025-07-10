-- Electricity prices fact table
-- Contains electricity price data at hourly granularity

{{ config(
    materialized='table',
    description='Fact table for electricity prices with hourly granularity',
    indexes=[
      {'columns': ['date_key', 'time_key', 'price_area_key']},
      {'columns': ['date_key']},
      {'columns': ['price_area_key']},
    ]
) }}

with electricity_prices_with_keys as (
    select
        -- Dimension keys
        to_char(p.date_utc, 'YYYYMMDD') as date_key,
        lpad(p.hour_utc::text, 2, '0') || '00' as time_key,  -- Hour start (00 minutes)
        'PA_' || p.price_area_code as price_area_key,
        
        -- Price measures
        p.spot_price_dkk,
        p.spot_price_eur,
        p.spot_price_dkk_calculated,
        p.exchange_rate_dkk_eur,
        
        -- Price analysis
        p.price_category,
        
        -- Calculate price volatility indicators
        lag(p.spot_price_eur) over (
            partition by p.price_area_code 
            order by p.timestamp_utc
        ) as prev_hour_price_eur,
        
        lead(p.spot_price_eur) over (
            partition by p.price_area_code 
            order by p.timestamp_utc
        ) as next_hour_price_eur,
        
        -- Price change calculations
        p.spot_price_eur - lag(p.spot_price_eur) over (
            partition by p.price_area_code 
            order by p.timestamp_utc
        ) as price_change_eur,
        
        -- Flags
        p.is_peak_hour,
        p.is_weekend,
        
        -- Timestamps for reference
        p.timestamp_utc,
        p.timestamp_dk,
        
        -- Metadata
        p.loaded_at
        
    from {{ ref('stg_electricity_prices') }} p
),

price_volatility_calc as (
    select
        *,
        
        -- Price volatility measures
        abs(price_change_eur) as price_volatility_eur,
        
        case 
            when prev_hour_price_eur > 0 
            then (price_change_eur / prev_hour_price_eur) * 100
            else 0 
        end as price_change_percentage,
        
        -- Price spike detection
        case 
            when abs(price_change_eur) > 50 then true
            else false 
        end as is_price_spike,
        
        case 
            when spot_price_eur < 0 then true
            else false 
        end as is_negative_price,
        
        -- Price level indicators
        case 
            when spot_price_eur > 200 then true
            else false 
        end as is_extreme_high_price,
        
        case 
            when spot_price_eur < 10 then true
            else false 
        end as is_very_low_price
        
    from electricity_prices_with_keys
),

fact_electricity_prices as (
    select
        -- Dimension keys
        date_key,
        time_key,
        price_area_key,
        
        -- Price measures
        spot_price_dkk,
        spot_price_eur,
        spot_price_dkk_calculated,
        exchange_rate_dkk_eur,
        
        -- Price analysis
        price_category,
        price_change_eur,
        price_volatility_eur,
        price_change_percentage,
        
        -- Price indicators
        is_price_spike,
        is_negative_price,
        is_extreme_high_price,
        is_very_low_price,
        
        -- Business flags
        is_peak_hour,
        is_weekend,
        
        -- Timestamps
        timestamp_utc,
        timestamp_dk,
        
        -- Metadata
        loaded_at,
        current_timestamp as processed_at
        
    from price_volatility_calc
    
    -- Data quality filters
    where date_key is not null
      and time_key is not null
      and price_area_key is not null
      and spot_price_eur is not null
)

select * from fact_electricity_prices

