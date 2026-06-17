-- sql/40_create_control_schema.sql

CREATE SCHEMA IF NOT EXISTS control;

CREATE TABLE IF NOT EXISTS control.load_watermark (
    table_name    VARCHAR PRIMARY KEY,
    last_load_dt  DATE,
    updated_at    TIMESTAMP DEFAULT current_timestamp
);

CREATE TABLE IF NOT EXISTS control.load_log (
    log_id       INTEGER,
    table_name   VARCHAR,
    load_type    VARCHAR,     -- 'FULL' or 'INCREMENTAL'
    rows_loaded  INTEGER,
    load_start   TIMESTAMP,
    load_end     TIMESTAMP,
    status       VARCHAR      -- 'SUCCESS' or 'ERROR'
);

-- Seed watermarks after initial load
INSERT OR REPLACE INTO control.load_watermark(table_name, last_load_dt)
SELECT 'orders', MAX(order_date) FROM staging.orders
UNION ALL
SELECT 'payments', MAX(payment_date) FROM staging.payments
UNION ALL
SELECT 'stock_movements', MAX(movement_date) FROM staging.stock_movements;
