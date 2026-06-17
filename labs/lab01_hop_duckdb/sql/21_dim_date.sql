-- sql/21_dim_date.sql
-- 1096 rows: 2024-01-01 to 2026-12-31 (2024 is a leap year)

INSERT INTO warehouse.dim_date
    (date_key, date_actual, year, quarter, month_num, month_name,
     day_num, day_name, day_of_week, is_weekend, season)
SELECT
    YEAR(d.dt)*10000 + MONTH(d.dt)*100 + DAY(d.dt)   AS date_key,
    d.dt                                               AS date_actual,
    YEAR(d.dt)                                         AS year,
    QUARTER(d.dt)                                      AS quarter,
    MONTH(d.dt)                                        AS month_num,
    MONTHNAME(d.dt)                                    AS month_name,
    DAY(d.dt)                                          AS day_num,
    DAYNAME(d.dt)                                      AS day_name,
    DAYOFWEEK(d.dt)                                    AS day_of_week,
    DAYOFWEEK(d.dt) IN (0, 6)                          AS is_weekend,
    CASE
        WHEN MONTH(d.dt) IN (12,1,2) THEN 'Winter'
        WHEN MONTH(d.dt) IN (3,4,5)  THEN 'Spring'
        WHEN MONTH(d.dt) IN (6,7,8)  THEN 'Summer'
        ELSE 'Autumn'
    END                                                AS season
FROM (
    SELECT UNNEST(
        GENERATE_SERIES(DATE '2024-01-01', DATE '2026-12-31', INTERVAL '1 day')
    ) AS dt
) d;
