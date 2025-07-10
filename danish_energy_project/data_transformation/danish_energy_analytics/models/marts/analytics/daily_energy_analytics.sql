-- Daily energy analytics mart
-- Aggregates energy data to daily level for reporting and analysis

{{ config(
    materialized='table',
    description='Daily aggregated energy analytics with KPIs and trends',
    indexes=[
      {'columns': ['date_key', 'price_area_key']},
      {'columns': ['date_key']},
    ]
) }}

with daily_production as (
    select
        p.date_key,
        p.price_area_key,
        
        -- Production aggregations
        sum(p.total_production_mwh) as total_production_mwh,
        sum(p.total_renewable_mwh) as total_renewable_mwh,
        sum(p.total_wind_mwh) as total_wind_mwh,
        sum(p.total_solar_mwh) as total_solar_mwh,
        sum(p.hydro_power_mwh) as total_hydro_mwh,
        
        -- Consumption aggregations
        sum(p.gross_consumption_mwh) as total_consumption_mwh,
        sum(p.total_grid_losses_mwh) as total_grid_losses_mwh,
        sum(p.net_exchange_mwh) as total_net_exchange_mwh,
        
        -- Calculate daily averages
        avg(p.renewable_percentage) as avg_renewable_percentage,
        avg(p.wind_percentage) as avg_wind_percentage,
        avg(p.solar_percentage) as avg_solar_percentage,
        avg(p.grid_efficiency_percentage) as avg_grid_efficiency_percentage,
        
        -- Peak hour analysis
        sum(case when p.is_peak_hour then p.total_production_mwh else 0 end) as peak_production_mwh,
        sum(case when p.is_peak_hour then p.total_renewable_mwh else 0 end) as peak_renewable_mwh,
        
        -- Weekend analysis
        max(p.is_weekend::int) as is_weekend_day
        
    from {{ ref('fact_energy_production') }} p
    group by p.date_key, p.price_area_key
),

daily_emissions as (
    select
        e.date_key,
        e.price_area_key,
        
        -- Emissions aggregations (convert 5-min to daily)
        avg(e.co2_emission_g_kwh) as avg_co2_emission_g_kwh,
        min(e.co2_emission_g_kwh) as min_co2_emission_g_kwh,
        max(e.co2_emission_g_kwh) as max_co2_emission_g_kwh,
        stddev(e.co2_emission_g_kwh) as stddev_co2_emission_g_kwh,
        
        -- Peak hour emissions
        avg(case when e.is_peak_hour then e.co2_emission_g_kwh end) as avg_peak_co2_emission_g_kwh
        
    from {{ ref('fact_co2_emissions') }} e
    group by e.date_key, e.price_area_key
),

daily_prices as (
    select
        pr.date_key,
        pr.price_area_key,
        
        -- Price aggregations
        avg(pr.spot_price_eur) as avg_spot_price_eur,
        min(pr.spot_price_eur) as min_spot_price_eur,
        max(pr.spot_price_eur) as max_spot_price_eur,
        stddev(pr.spot_price_eur) as price_volatility_eur,
        
        -- Peak hour prices
        avg(case when pr.is_peak_hour then pr.spot_price_eur end) as avg_peak_price_eur,
        
        -- Price spike analysis
        sum(case when pr.is_price_spike then 1 else 0 end) as price_spike_hours,
        sum(case when pr.is_negative_price then 1 else 0 end) as negative_price_hours,
        
        -- Price categories
        sum(case when pr.price_category = 'Very High' then 1 else 0 end) as very_high_price_hours
        
    from {{ ref('fact_electricity_prices') }} pr
    group by pr.date_key, pr.price_area_key
),

daily_analytics as (
    select
        -- Dimension keys
        coalesce(p.date_key, e.date_key, pr.date_key) as date_key,
        coalesce(p.price_area_key, e.price_area_key, pr.price_area_key) as price_area_key,
        
        -- Production metrics
        coalesce(p.total_production_mwh, 0) as total_production_mwh,
        coalesce(p.total_renewable_mwh, 0) as total_renewable_mwh,
        coalesce(p.total_wind_mwh, 0) as total_wind_mwh,
        coalesce(p.total_solar_mwh, 0) as total_solar_mwh,
        coalesce(p.total_hydro_mwh, 0) as total_hydro_mwh,
        
        -- Consumption metrics
        coalesce(p.total_consumption_mwh, 0) as total_consumption_mwh,
        coalesce(p.total_grid_losses_mwh, 0) as total_grid_losses_mwh,
        coalesce(p.total_net_exchange_mwh, 0) as total_net_exchange_mwh,
        
        -- Efficiency metrics
        coalesce(p.avg_renewable_percentage, 0) as avg_renewable_percentage,
        coalesce(p.avg_wind_percentage, 0) as avg_wind_percentage,
        coalesce(p.avg_solar_percentage, 0) as avg_solar_percentage,
        coalesce(p.avg_grid_efficiency_percentage, 0) as avg_grid_efficiency_percentage,
        
        -- Peak analysis
        coalesce(p.peak_production_mwh, 0) as peak_production_mwh,
        coalesce(p.peak_renewable_mwh, 0) as peak_renewable_mwh,
        
        -- Emissions metrics
        e.avg_co2_emission_g_kwh,
        e.min_co2_emission_g_kwh,
        e.max_co2_emission_g_kwh,
        e.stddev_co2_emission_g_kwh,
        e.avg_peak_co2_emission_g_kwh,
        
        -- Price metrics
        pr.avg_spot_price_eur,
        pr.min_spot_price_eur,
        pr.max_spot_price_eur,
        pr.price_volatility_eur,
        pr.avg_peak_price_eur,
        pr.price_spike_hours,
        pr.negative_price_hours,
        pr.very_high_price_hours,
        
        -- Calculated KPIs
        case 
            when p.total_production_mwh > 0 
            then (p.total_renewable_mwh / p.total_production_mwh) * 100
            else 0 
        end as daily_renewable_percentage,
        
        case 
            when p.total_consumption_mwh > 0 
            then ((p.total_consumption_mwh - p.total_grid_losses_mwh) / p.total_consumption_mwh) * 100
            else 0 
        end as daily_grid_efficiency_percentage,
        
        -- Energy balance
        p.total_production_mwh + p.total_net_exchange_mwh - p.total_consumption_mwh as energy_balance_mwh,
        
        -- Flags
        coalesce(p.is_weekend_day::boolean, false) as is_weekend_day,
        
        -- Metadata
        current_timestamp as processed_at
        
    from daily_production p
    full outer join daily_emissions e 
        on p.date_key = e.date_key 
        and p.price_area_key = e.price_area_key
    full outer join daily_prices pr 
        on coalesce(p.date_key, e.date_key) = pr.date_key 
        and coalesce(p.price_area_key, e.price_area_key) = pr.price_area_key
)

select * from daily_analytics
where date_key is not null and price_area_key is not null
order by date_key, price_area_key

