-- Re-generate calendar 1 Jan 2019 → 31 Dec 2025 (2 557 rows)
INSERT INTO core.dim_date (
    date_key,        date_actual,
    year,            quarter,        quarter_name,
    month,           month_name,     month_name_short,
    week_of_year,
    day_of_year,     day_of_month,
    day_of_week,     day_name,       day_name_short,
    is_weekend,      is_weekday,
    season,          is_danish_holiday,
    date_last_year,  date_last_month,
    date_last_week,  date_yesterday,
    fiscal_year,     iso_year,       iso_week,
    date_iso,        date_european,  date_american
)
SELECT
    to_char(d,'YYYYMMDD')                       AS date_key,
    d                                           AS date_actual,
    EXTRACT(year    FROM d)::int                AS year,
    EXTRACT(quarter FROM d)::int                AS quarter,
    'Q' || EXTRACT(quarter FROM d)              AS quarter_name,
    EXTRACT(month   FROM d)::int                AS month,
    to_char(d,'FMMonth')                        AS month_name,
    to_char(d,'Mon')                            AS month_name_short,
    EXTRACT(week    FROM d)::int                AS week_of_year,
    EXTRACT(doy     FROM d)::int                AS day_of_year,
    EXTRACT(day     FROM d)::int                AS day_of_month,
    EXTRACT(isodow  FROM d)::int                AS day_of_week,
    to_char(d,'FMDay')                          AS day_name,
    to_char(d,'Dy')                             AS day_name_short,
    (EXTRACT(isodow FROM d) IN (6,7))           AS is_weekend,
    NOT (EXTRACT(isodow FROM d) IN (6,7))       AS is_weekday,
    CASE
        WHEN EXTRACT(month FROM d) IN (12,1,2) THEN 'Winter'
        WHEN EXTRACT(month FROM d) IN (3,4,5)  THEN 'Spring'
        WHEN EXTRACT(month FROM d) IN (6,7,8)  THEN 'Summer'
        ELSE 'Autumn'
    END                                          AS season,
    FALSE                                        AS is_danish_holiday,
    (d - INTERVAL '1 year')::date               AS date_last_year,
    (d - INTERVAL '1 month')::date              AS date_last_month,
    (d - INTERVAL '1 week')::date               AS date_last_week,
    (d - INTERVAL '1 day')::date                AS date_yesterday,
    EXTRACT(year    FROM d)::int                AS fiscal_year,
    EXTRACT(isoyear FROM d)::int                AS iso_year,
    EXTRACT(week    FROM d)::int                AS iso_week,
    to_char(d,'YYYY-MM-DD')                     AS date_iso,
    to_char(d,'DD/MM/YYYY')                     AS date_european,
    to_char(d,'MM/DD/YYYY')                     AS date_american
FROM generate_series('2019-01-01'::date,
                     '2025-12-31'::date,
                     INTERVAL '1 day') AS g(d)
ON CONFLICT (date_key) DO NOTHING;
