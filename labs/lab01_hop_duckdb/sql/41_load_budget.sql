-- sql/41_load_budget.sql

TRUNCATE warehouse.fact_budget;

INSERT INTO warehouse.fact_budget
    (budget_id, year, month_num, category_id, category_name,
     channel_key, budget_amount, budget_qty, loaded_at)
SELECT
    b.budget_id,
    b.year,
    b.month        AS month_num,
    b.category_id,
    c.category_name,
    dch.channel_key,
    b.budget_amount,
    b.budget_qty,
    CURRENT_TIMESTAMP AS loaded_at
FROM staging.budget b
LEFT JOIN staging.categories c     ON b.category_id = c.category_id
LEFT JOIN warehouse.dim_channel dch ON b.channel = dch.channel_name;
