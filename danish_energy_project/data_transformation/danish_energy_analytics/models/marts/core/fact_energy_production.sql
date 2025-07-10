-- Energy production fact table
-- Contains energy production data by source at hourly granularity

{{ config(
    materialized='table',
    description='Fact table for energy production by source with hourly granularity',
    indexes=[
      {'columns': ['date_key', 'time_key', 'price_area_key']},
      {'columns': ['date_key']},
      {'columns': ['price_area_key']},
    ]
) }}

with energy_production_with_keys as (
    select
        -- Dimension keys
        to_char(e.date_utc, 'YYYYMMDD') as date_key,
        lpad(e.hour_utc::text, 2, '0') || '00' as time_key,  -- Hour start (00 minutes)
        'PA_' || e.price_area_code as price_area_key,
        
        -- Production measures by source
        e.central_power_mwh,
        e.local_power_mwh,
        e.commercial_power_mwh,
        e.local_power_self_con_mwh,
        
        -- Wind power measures
        e.offshore_wind_lt100mw_mwh,
        e.offshore_wind_ge100mw_mwh,
        e.onshore_wind_lt50kw_mwh,
        e.onshore_wind_ge50kw_mwh,
        e.total_wind_mwh,
        
        -- Other renewable measures
        e.hydro_power_mwh,
        e.solar_power_lt10kw_mwh,
        e.solar_power_ge10lt40kw_mwh,
        e.solar_power_ge40kw_mwh,
        e.solar_power_self_con_mwh,
        e.total_solar_mwh,
        
        -- Totals
        e.total_renewable_mwh,
        e.total_production_mwh,
        e.unknown_prod_mwh,
        
        -- Consumption measures
        e.gross_consumption_mwh,
        e.grid_loss_transmission_mwh,
        e.grid_loss_interconnectors_mwh,
        e.grid_loss_distribution_mwh,
        e.total_grid_losses_mwh,
        e.power_to_heat_mwh,
        
        -- Exchange measures
        e.exchange_no_mwh,
        e.exchange_se_mwh,
        e.exchange_ge_mwh,
        e.exchange_nl_mwh,
        e.exchange_gb_mwh,
        e.exchange_great_belt_mwh,
        e.net_exchange_mwh,
        
        -- Calculated percentages
        case 
            when e.total_production_mwh > 0 
            then (e.total_renewable_mwh / e.total_production_mwh) * 100
            else 0 
        end as renewable_percentage,
        
        case 
            when e.total_production_mwh > 0 
            then (e.total_wind_mwh / e.total_production_mwh) * 100
            else 0 
        end as wind_percentage,
        
        case 
            when e.total_production_mwh > 0 
            then (e.total_solar_mwh / e.total_production_mwh) * 100
            else 0 
        end as solar_percentage,
        
        case 
            when e.gross_consumption_mwh > 0 
            then ((e.gross_consumption_mwh - e.total_grid_losses_mwh) / e.gross_consumption_mwh) * 100
            else 0 
        end as grid_efficiency_percentage,
        
        -- Production categories
        case 
            when e.total_renewable_mwh / nullif(e.total_production_mwh, 0) >= 0.8 then 'Very High Renewable'
            when e.total_renewable_mwh / nullif(e.total_production_mwh, 0) >= 0.6 then 'High Renewable'
            when e.total_renewable_mwh / nullif(e.total_production_mwh, 0) >= 0.4 then 'Medium Renewable'
            when e.total_renewable_mwh / nullif(e.total_production_mwh, 0) >= 0.2 then 'Low Renewable'
            else 'Very Low Renewable'
        end as renewable_category,
        
        -- Flags
        e.is_peak_hour,
        e.is_weekend,
        
        -- Timestamps for reference
        e.timestamp_utc,
        e.timestamp_dk,
        
        -- Metadata
        e.loaded_at
        
    from {{ ref('stg_renewable_energy') }} e
),

fact_energy_production as (
    select
        -- Dimension keys
        date_key,
        time_key,
        price_area_key,
        
        -- Production measures
        central_power_mwh,
        local_power_mwh,
        commercial_power_mwh,
        local_power_self_con_mwh,
        
        -- Wind power
        offshore_wind_lt100mw_mwh,
        offshore_wind_ge100mw_mwh,
        onshore_wind_lt50kw_mwh,
        onshore_wind_ge50kw_mwh,
        total_wind_mwh,
        
        -- Other renewables
        hydro_power_mwh,
        solar_power_lt10kw_mwh,
        solar_power_ge10lt40kw_mwh,
        solar_power_ge40kw_mwh,
        solar_power_self_con_mwh,
        total_solar_mwh,
        
        -- Totals
        total_renewable_mwh,
        total_production_mwh,
        unknown_prod_mwh,
        
        -- Consumption
        gross_consumption_mwh,
        grid_loss_transmission_mwh,
        grid_loss_interconnectors_mwh,
        grid_loss_distribution_mwh,
        total_grid_losses_mwh,
        power_to_heat_mwh,
        
        -- Exchange
        exchange_no_mwh,
        exchange_se_mwh,
        exchange_ge_mwh,
        exchange_nl_mwh,
        exchange_gb_mwh,
        exchange_great_belt_mwh,
        net_exchange_mwh,
        
        -- Calculated measures
        renewable_percentage,
        wind_percentage,
        solar_percentage,
        grid_efficiency_percentage,
        renewable_category,
        
        -- Business flags
        is_peak_hour,
        is_weekend,
        
        -- Timestamps
        timestamp_utc,
        timestamp_dk,
        
        -- Metadata
        loaded_at,
        current_timestamp as processed_at
        
    from energy_production_with_keys
    
    -- Data quality filters
    where date_key is not null
      and time_key is not null
      and price_area_key is not null
)

select * from fact_energy_production

