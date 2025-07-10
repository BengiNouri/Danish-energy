-- Price area dimension table
-- Provides geographic and market area attributes

{{ config(
    materialized='table',
    description='Price area dimension with geographic and market attributes',
    indexes=[
      {'columns': ['price_area_key'], 'unique': True},
      {'columns': ['price_area_code']},
    ]
) }}

with price_areas as (
    select distinct 
        price_area_code
    from {{ ref('stg_electricity_prices') }}
    
    union
    
    select distinct 
        price_area_code
    from {{ ref('stg_renewable_energy') }}
    
    union
    
    select distinct 
        price_area_code
    from {{ ref('stg_co2_emissions') }}
),

price_area_dimension as (
    select
        -- Surrogate key
        'PA_' || price_area_code as price_area_key,
        
        -- Natural key
        price_area_code,
        
        -- Area attributes based on known Nordic electricity market structure
        case 
            when price_area_code = 'DK1' then 'Denmark West'
            when price_area_code = 'DK2' then 'Denmark East'
            when price_area_code = 'DE' then 'Germany'
            when price_area_code = 'NO1' then 'Norway South'
            when price_area_code = 'NO2' then 'Norway Southwest'
            when price_area_code = 'NO3' then 'Norway Central'
            when price_area_code = 'NO4' then 'Norway North'
            when price_area_code = 'NO5' then 'Norway West'
            when price_area_code = 'SE1' then 'Sweden North'
            when price_area_code = 'SE2' then 'Sweden Central'
            when price_area_code = 'SE3' then 'Sweden South'
            when price_area_code = 'SE4' then 'Sweden Southeast'
            when price_area_code = 'FI' then 'Finland'
            when price_area_code = 'EE' then 'Estonia'
            when price_area_code = 'LV' then 'Latvia'
            when price_area_code = 'LT' then 'Lithuania'
            when price_area_code = 'PL' then 'Poland'
            when price_area_code = 'NL' then 'Netherlands'
            when price_area_code = 'BE' then 'Belgium'
            when price_area_code = 'GB' then 'Great Britain'
            when price_area_code = 'GB2' then 'Great Britain Zone 2'
            when price_area_code = 'SYSTEM' then 'System Price'
            else price_area_code
        end as price_area_name,
        
        -- Country mapping
        case 
            when price_area_code like 'DK%' then 'Denmark'
            when price_area_code like 'NO%' then 'Norway'
            when price_area_code like 'SE%' then 'Sweden'
            when price_area_code = 'FI' then 'Finland'
            when price_area_code = 'DE' then 'Germany'
            when price_area_code = 'EE' then 'Estonia'
            when price_area_code = 'LV' then 'Latvia'
            when price_area_code = 'LT' then 'Lithuania'
            when price_area_code = 'PL' then 'Poland'
            when price_area_code = 'NL' then 'Netherlands'
            when price_area_code = 'BE' then 'Belgium'
            when price_area_code like 'GB%' then 'United Kingdom'
            when price_area_code = 'SYSTEM' then 'Nordic System'
            else 'Unknown'
        end as country,
        
        -- Region mapping
        case 
            when price_area_code in ('DK1', 'DK2') then 'Denmark'
            when price_area_code like 'NO%' then 'Norway'
            when price_area_code like 'SE%' then 'Sweden'
            when price_area_code = 'FI' then 'Finland'
            when price_area_code in ('EE', 'LV', 'LT') then 'Baltics'
            when price_area_code in ('DE', 'NL', 'BE', 'PL') then 'Continental Europe'
            when price_area_code like 'GB%' then 'Great Britain'
            when price_area_code = 'SYSTEM' then 'Nordic System'
            else 'Other'
        end as region,
        
        -- Market attributes
        case 
            when price_area_code in ('DK1', 'DK2') then true
            else false 
        end as is_danish_area,
        
        case 
            when price_area_code in ('DK1', 'DK2', 'NO1', 'NO2', 'NO3', 'NO4', 'NO5', 'SE1', 'SE2', 'SE3', 'SE4', 'FI') 
            then true
            else false 
        end as is_nordic_area,
        
        case 
            when price_area_code = 'SYSTEM' then true
            else false 
        end as is_system_price,
        
        -- Grid operator mapping
        case 
            when price_area_code in ('DK1', 'DK2') then 'Energinet'
            when price_area_code like 'NO%' then 'Statnett'
            when price_area_code like 'SE%' then 'Svenska kraftnät'
            when price_area_code = 'FI' then 'Fingrid'
            when price_area_code = 'DE' then 'Multiple TSOs'
            when price_area_code = 'NL' then 'TenneT NL'
            when price_area_code like 'GB%' then 'National Grid ESO'
            else 'Unknown'
        end as grid_operator,
        
        -- Time zone
        case 
            when price_area_code in ('DK1', 'DK2', 'DE', 'NL', 'BE', 'PL') then 'CET'
            when price_area_code like 'NO%' or price_area_code like 'SE%' then 'CET'
            when price_area_code in ('FI', 'EE', 'LV', 'LT') then 'EET'
            when price_area_code like 'GB%' then 'GMT'
            else 'CET'
        end as time_zone,
        
        -- Renewable energy characteristics
        case 
            when price_area_code in ('DK1', 'DK2') then 'High Wind'
            when price_area_code like 'NO%' then 'High Hydro'
            when price_area_code like 'SE%' then 'Mixed Hydro/Nuclear'
            when price_area_code = 'DE' then 'Mixed Renewable'
            else 'Mixed'
        end as renewable_profile
        
    from price_areas
)

select * from price_area_dimension
order by price_area_code

