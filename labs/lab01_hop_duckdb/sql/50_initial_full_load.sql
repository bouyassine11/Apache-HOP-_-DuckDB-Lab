-- sql/50_initial_full_load.sql
-- Run once: builds the complete warehouse from typed staging CSV loads.
-- In DuckDB CLI:  .read sql/50_initial_full_load.sql

.read sql/00_create_schema.sql
.read sql/10_create_staging_schema.sql
.read sql/01_load_staging_tables.sql
.read sql/20_create_warehouse_schema.sql
.read sql/21_dim_date.sql
.read sql/22_dim_customer.sql
.read sql/23_dim_product.sql
.read sql/24_dim_channel.sql
.read sql/30_fact_sales.sql
.read sql/31_fact_stock.sql
.read sql/40_create_control_schema.sql
.read sql/41_load_budget.sql

SELECT 'FULL LOAD COMPLETE' AS status,
       (SELECT COUNT(*) FROM warehouse.fact_sales)  AS fact_sales_rows,
       (SELECT COUNT(*) FROM warehouse.fact_stock)  AS fact_stock_rows,
       (SELECT COUNT(*) FROM warehouse.fact_budget) AS fact_budget_rows,
       (SELECT MAX(order_date) FROM staging.orders) AS latest_order_date;
