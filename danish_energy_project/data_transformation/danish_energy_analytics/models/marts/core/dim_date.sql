-- Date dimension table
-- Provides comprehensive date attributes for time-based analysis

{{ config(
    materialized='table',
    description='Date dimension with business calendar attributes',
    indexes=[
      {'columns': ['date_key'], 'unique': True},
      {'columns': ['date_actual']},
      {'columns': ['year', 'month']},
    ]
) }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('" ~ var('start_date') ~ "' as date)",
        end_date="cast('" ~ var('end_date') ~ "' as date)"
    ) }}
),

date_dimension as (
    select
        -- Surrogate key
        to_char(date_day, 'YYYYMMDD') as date_key,
        
        -- Natural key
        date_day as date_actual,
        
        -- Year attributes
        extract(year from date_day) as year,
        extract(quarter from date_day) as quarter,
        'Q' || extract(quarter from date_day) as quarter_name,
        
        -- Month attributes
        extract(month from date_day) as month,
        to_char(date_day, 'Month') as month_name,
        to_char(date_day, 'Mon') as month_name_short,
        
        -- Week attributes
        extract(week from date_day) as week_of_year,
        extract(dow from date_day) as day_of_week,  -- 0=Sunday, 6=Saturday
        to_char(date_day, 'Day') as day_name,
        to_char(date_day, 'Dy') as day_name_short,
        
        -- Day attributes
        extract(doy from date_day) as day_of_year,
        extract(day from date_day) as day_of_month,
        
        -- Business logic flags
        case 
            when extract(dow from date_day) in (0, 6) 
            then true 
            else false 
        end as is_weekend,
        
        case 
            when extract(dow from date_day) between 1 and 5 
            then true 
            else false 
        end as is_weekday,
        
        -- Season calculation (Northern Hemisphere)
        case 
            when extract(month from date_day) in (12, 1, 2) then 'Winter'
            when extract(month from date_day) in (3, 4, 5) then 'Spring'
            when extract(month from date_day) in (6, 7, 8) then 'Summer'
            when extract(month from date_day) in (9, 10, 11) then 'Autumn'
        end as season,
        
        -- Danish holidays (simplified - major holidays only)
        case 
            when extract(month from date_day) = 1 and extract(day from date_day) = 1 then true  -- New Year
            when extract(month from date_day) = 12 and extract(day from date_day) = 25 then true -- Christmas
            when extract(month from date_day) = 12 and extract(day from date_day) = 26 then true -- Boxing Day
            when extract(month from date_day) = 6 and extract(day from date_day) = 5 then true  -- Constitution Day
            else false
        end as is_danish_holiday,
        
        -- Relative date calculations
        date_day - interval '1 year' as date_last_year,
        date_day - interval '1 month' as date_last_month,
        date_day - interval '1 week' as date_last_week,
        date_day - interval '1 day' as date_yesterday,
        
        -- Fiscal year (assuming calendar year for Denmark)
        extract(year from date_day) as fiscal_year,
        
        -- ISO week date
        extract(isoyear from date_day) as iso_year,
        extract(week from date_day) as iso_week,
        
        -- Date formatting
        to_char(date_day, 'YYYY-MM-DD') as date_iso,
        to_char(date_day, 'DD/MM/YYYY') as date_european,
        to_char(date_day, 'MM/DD/YYYY') as date_american
        
    from date_spine
)

select * from date_dimension
order by date_actual

