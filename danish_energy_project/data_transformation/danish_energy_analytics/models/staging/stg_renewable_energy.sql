-- Staging model for renewable energy production data
-- Cleans and standardizes raw renewable energy data from the API

{{ config(
    materialized='view',
    description='Cleaned renewable energy production data with calculated totals and standardized measures'
) }}

with source_data as (
    select
        -- Parse timestamps
        cast(hourutc as timestamp) as timestamp_utc,
        cast(hourdk as timestamp) as timestamp_dk,
        
        -- Geographic dimension
        trim(upper(pricearea)) as price_area_code,
        
        -- Production measures (convert null to 0)
        coalesce(cast(centralpowermwh as decimal(12,3)), 0) as central_power_mwh,
        coalesce(cast(localpowermwh as decimal(12,3)), 0) as local_power_mwh,
        coalesce(cast(commercialpowermwh as decimal(12,3)), 0) as commercial_power_mwh,
        coalesce(cast(localpowerselfconmwh as decimal(12,3)), 0) as local_power_self_con_mwh,
        
        -- Wind power
        coalesce(cast(offshorewindlt100mw_mwh as decimal(12,3)), 0) as offshore_wind_lt100mw_mwh,
        coalesce(cast(offshorewindge100mw_mwh as decimal(12,3)), 0) as offshore_wind_ge100mw_mwh,
        coalesce(cast(onshorewindlt50kw_mwh as decimal(12,3)), 0) as onshore_wind_lt50kw_mwh,
        coalesce(cast(onshorewindge50kw_mwh as decimal(12,3)), 0) as onshore_wind_ge50kw_mwh,
        
        -- Other renewables
        coalesce(cast(hydropowermwh as decimal(12,3)), 0) as hydro_power_mwh,
        coalesce(cast(solarpowerlt10kw_mwh as decimal(12,3)), 0) as solar_power_lt10kw_mwh,
        coalesce(cast(solarpowerge10lt40kw_mwh as decimal(12,3)), 0) as solar_power_ge10lt40kw_mwh,
        coalesce(cast(solarpowerge40kw_mwh as decimal(12,3)), 0) as solar_power_ge40kw_mwh,
        coalesce(cast(solarpowerselfconmwh as decimal(12,3)), 0) as solar_power_self_con_mwh,
        
        -- Consumption and exchange
        coalesce(cast(grossconsumptionmwh as decimal(12,3)), 0) as gross_consumption_mwh,
        coalesce(cast(gridlosstransmissionmwh as decimal(12,3)), 0) as grid_loss_transmission_mwh,
        coalesce(cast(gridlossinterconnectorsmwh as decimal(12,3)), 0) as grid_loss_interconnectors_mwh,
        coalesce(cast(gridlossdistributionmwh as decimal(12,3)), 0) as grid_loss_distribution_mwh,
        coalesce(cast(powertoheatmwh as decimal(12,3)), 0) as power_to_heat_mwh,
        
        -- Exchange with neighboring countries
        coalesce(cast(exchangeno_mwh as decimal(12,3)), 0) as exchange_no_mwh,
        coalesce(cast(exchangese_mwh as decimal(12,3)), 0) as exchange_se_mwh,
        coalesce(cast(exchangege_mwh as decimal(12,3)), 0) as exchange_ge_mwh,
        coalesce(cast(exchangenl_mwh as decimal(12,3)), 0) as exchange_nl_mwh,
        coalesce(cast(exchangegb_mwh as decimal(12,3)), 0) as exchange_gb_mwh,
        coalesce(cast(exchangegreatbelt_mwh as decimal(12,3)), 0) as exchange_great_belt_mwh,
        
        -- Unknown production
        coalesce(cast(unknownprodmwh as decimal(12,3)), 0) as unknown_prod_mwh,
        
        -- Metadata
        current_timestamp as loaded_at
        
    from {{ source('raw_energy', 'renewable_energy') }}
    
    where 
        -- Data quality filters
        hourutc is not null
        and pricearea is not null
),

calculated_measures as (
    select
        *,
        
        -- Calculate renewable energy totals
        (offshore_wind_lt100mw_mwh + offshore_wind_ge100mw_mwh + 
         onshore_wind_lt50kw_mwh + onshore_wind_ge50kw_mwh) as total_wind_mwh,
        
        (solar_power_lt10kw_mwh + solar_power_ge10lt40kw_mwh + 
         solar_power_ge40kw_mwh + solar_power_self_con_mwh) as total_solar_mwh,
        
        (offshore_wind_lt100mw_mwh + offshore_wind_ge100mw_mwh + 
         onshore_wind_lt50kw_mwh + onshore_wind_ge50kw_mwh +
         hydro_power_mwh + solar_power_lt10kw_mwh + 
         solar_power_ge10lt40kw_mwh + solar_power_ge40kw_mwh + 
         solar_power_self_con_mwh) as total_renewable_mwh,
        
        -- Calculate total production
        (central_power_mwh + local_power_mwh + commercial_power_mwh +
         offshore_wind_lt100mw_mwh + offshore_wind_ge100mw_mwh + 
         onshore_wind_lt50kw_mwh + onshore_wind_ge50kw_mwh +
         hydro_power_mwh + solar_power_lt10kw_mwh + 
         solar_power_ge10lt40kw_mwh + solar_power_ge40kw_mwh + 
         unknown_prod_mwh) as total_production_mwh,
        
        -- Calculate total grid losses
        (grid_loss_transmission_mwh + grid_loss_interconnectors_mwh + 
         grid_loss_distribution_mwh) as total_grid_losses_mwh,
        
        -- Calculate net exchange
        (exchange_no_mwh + exchange_se_mwh + exchange_ge_mwh + 
         exchange_nl_mwh + exchange_gb_mwh + exchange_great_belt_mwh) as net_exchange_mwh,
        
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
        end as is_weekend
        
    from source_data
)

select * from calculated_measures

