-- Time dimension table
-- Provides time-of-day attributes for intraday analysis

{{ config(
    materialized='table',
    description='Time dimension with hour and minute granularity for intraday analysis',
    indexes=[
      {'columns': ['time_key'], 'unique': True},
      {'columns': ['hour', 'minute']},
    ]
) }}

with time_spine as (
    -- Generate all possible hour and minute combinations
    select 
        h.hour,
        m.minute
    from (
        select generate_series(0, 23) as hour
    ) h
    cross join (
        select generate_series(0, 55, 5) as minute  -- 5-minute intervals
    ) m
),

time_dimension as (
    select
        -- Surrogate key
        lpad(hour::text, 2, '0') || lpad(minute::text, 2, '0') as time_key,
        
        -- Time attributes
        hour,
        minute,
        
        -- Time formatting
        lpad(hour::text, 2, '0') || ':' || lpad(minute::text, 2, '0') as time_24hr,
        case 
            when hour = 0 then '12:' || lpad(minute::text, 2, '0') || ' AM'
            when hour < 12 then lpad(hour::text, 2, '0') || ':' || lpad(minute::text, 2, '0') || ' AM'
            when hour = 12 then '12:' || lpad(minute::text, 2, '0') || ' PM'
            else lpad((hour - 12)::text, 2, '0') || ':' || lpad(minute::text, 2, '0') || ' PM'
        end as time_12hr,
        
        -- Time periods
        case 
            when hour between 0 and 5 then 'Night'
            when hour between 6 and 11 then 'Morning'
            when hour between 12 and 17 then 'Afternoon'
            when hour between 18 and 23 then 'Evening'
        end as time_of_day,
        
        case 
            when hour between 6 and 9 then 'Morning Peak'
            when hour between 17 and 20 then 'Evening Peak'
            when hour between 10 and 16 then 'Daytime'
            when hour between 21 and 23 then 'Evening Off-Peak'
            else 'Night'
        end as energy_period,
        
        -- Business logic flags
        case 
            when hour between {{ var('peak_hours_start') }} and {{ var('peak_hours_end') }}
            then true 
            else false 
        end as is_peak_hour,
        
        case 
            when hour between {{ var('business_hours_start') }} and {{ var('business_hours_end') }}
            then true 
            else false 
        end as is_business_hour,
        
        case 
            when hour between 22 and 23 or hour between 0 and 6
            then true 
            else false 
        end as is_night_hour,
        
        -- Energy market periods (simplified Danish market structure)
        case 
            when hour between 0 and 5 then 'Base Load'
            when hour between 6 and 8 then 'Morning Ramp'
            when hour between 9 and 16 then 'Day Load'
            when hour between 17 and 20 then 'Peak Load'
            when hour between 21 and 23 then 'Evening Ramp'
        end as load_period,
        
        -- Solar generation potential (simplified)
        case 
            when hour between 6 and 18 then true
            else false 
        end as is_solar_hours,
        
        case 
            when hour between 10 and 14 then 'Peak Solar'
            when hour between 8 and 9 or hour between 15 and 17 then 'Good Solar'
            when hour between 6 and 7 or hour between 18 and 19 then 'Low Solar'
            else 'No Solar'
        end as solar_potential,
        
        -- Minute-specific attributes
        case 
            when minute = 0 then true 
            else false 
        end as is_hour_start,
        
        case 
            when minute in (0, 15, 30, 45) then true 
            else false 
        end as is_quarter_hour,
        
        -- Calculate total minutes from midnight
        hour * 60 + minute as minutes_from_midnight
        
    from time_spine
)

select * from time_dimension
order by hour, minute

