-- sql/52_actuals_vs_budget.sql

-- Actual vs Budget by Month x Category x Channel
SELECT
    dd.year,
    dd.month_num,
    dd.month_name,
    dp.category_name,
    dch.channel_name,
    ROUND(SUM(fs.net_amount), 2)                                     AS actual_revenue,
    MAX(fb.budget_amount)                                            AS budget_revenue,
    ROUND(
        SUM(fs.net_amount) / NULLIF(MAX(fb.budget_amount), 0) * 100, 1
    )                                                                AS achievement_pct
FROM warehouse.fact_sales       fs
JOIN warehouse.dim_date         dd  ON fs.date_key     = dd.date_key
JOIN warehouse.dim_product      dp  ON fs.product_key  = dp.product_key
JOIN warehouse.dim_channel      dch ON fs.channel_key  = dch.channel_key
LEFT JOIN warehouse.fact_budget fb
    ON  dd.year         = fb.year
    AND dd.month_num    = fb.month_num
    AND dp.category_id  = fb.category_id
    AND dch.channel_key = fb.channel_key
WHERE fs.order_status = 'Completed'
GROUP BY dd.year, dd.month_num, dd.month_name, dp.category_name, dch.channel_name
ORDER BY dd.year, dd.month_num, dp.category_name;

-- Global achievement rate by month
-- Both sides are aggregated in CTEs before joining to avoid fan-out
-- (fact_budget grain is month×category×channel; joining directly to fact_sales
--  would multiply the budget by the number of sales rows per month).
WITH sales_by_month AS (
    SELECT dd.year, dd.month_num, dd.month_name,
           SUM(fs.net_amount) AS actual_total
    FROM warehouse.fact_sales    fs
    JOIN warehouse.dim_date      dd ON fs.date_key = dd.date_key
    WHERE fs.order_status = 'Completed'
    GROUP BY dd.year, dd.month_num, dd.month_name
),
budget_by_month AS (
    SELECT year, month_num, SUM(budget_amount) AS budget_total
    FROM warehouse.fact_budget
    GROUP BY year, month_num
)
SELECT
    s.year,
    s.month_num,
    s.month_name,
    ROUND(s.actual_total, 2)                                        AS actual_total,
    b.budget_total,
    ROUND(s.actual_total / NULLIF(b.budget_total, 0) * 100, 1)     AS pct_of_budget
FROM sales_by_month      s
LEFT JOIN budget_by_month b ON s.year = b.year AND s.month_num = b.month_num
ORDER BY s.year, s.month_num;
