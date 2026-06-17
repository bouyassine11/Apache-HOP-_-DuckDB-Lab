-- sql/51_incremental_load.sql
-- Appends April 2025 batch directly to staging (watermark-filtered),
-- then rebuilds fact_sales.

-- 1. Register new batch files as temporary typed tables.
CREATE OR REPLACE TEMP TABLE orders_batch2 AS
SELECT
    order_id::INTEGER AS order_id,
    customer_id::INTEGER AS customer_id,
    order_date::DATE AS order_date,
    channel::VARCHAR AS channel,
    order_status::VARCHAR AS order_status,
    city::VARCHAR AS city
FROM read_csv_auto('data/raw/orders_april.csv', header=true, nullstr='');

CREATE OR REPLACE TEMP TABLE order_items_batch2 AS
SELECT
    order_item_id::INTEGER AS order_item_id,
    order_id::INTEGER AS order_id,
    product_id::INTEGER AS product_id,
    quantity::INTEGER AS quantity,
    unit_price::DECIMAL(10,2) AS unit_price,
    discount_amount::DECIMAL(10,2) AS discount_amount
FROM read_csv_auto('data/raw/order_items_april.csv', header=true, nullstr='');

CREATE OR REPLACE TEMP TABLE payments_batch2 AS
SELECT
    payment_id::INTEGER AS payment_id,
    order_id::INTEGER AS order_id,
    payment_date::DATE AS payment_date,
    payment_method::VARCHAR AS payment_method,
    payment_status::VARCHAR AS payment_status,
    amount::DECIMAL(10,2) AS amount
FROM read_csv_auto('data/raw/payments_april.csv', header=true, nullstr='');

-- 2. Append typed rows to staging. Deduplication here only prevents rerun duplicates.
INSERT INTO staging.orders
SELECT b.*
FROM orders_batch2 b
WHERE b.order_date > (
    SELECT COALESCE(MAX(last_load_dt), DATE '2000-01-01')
    FROM control.load_watermark WHERE table_name = 'orders'
)
AND NOT EXISTS (
    SELECT 1 FROM staging.orders s WHERE s.order_id = b.order_id
);

INSERT INTO staging.order_items
SELECT b.*
FROM order_items_batch2 b
WHERE NOT EXISTS (
    SELECT 1 FROM staging.order_items s WHERE s.order_item_id = b.order_item_id
);

INSERT INTO staging.payments
SELECT b.*
FROM payments_batch2 b
WHERE b.payment_date > (
    SELECT COALESCE(MAX(last_load_dt), DATE '2000-01-01')
    FROM control.load_watermark WHERE table_name = 'payments'
)
AND NOT EXISTS (
    SELECT 1 FROM staging.payments s WHERE s.payment_id = b.payment_id
);

-- 3. Rebuild fact_sales (full refresh - simpler for this lab)
.read sql/30_fact_sales.sql

-- 4. Update watermarks
INSERT OR REPLACE INTO control.load_watermark(table_name, last_load_dt, updated_at)
SELECT 'orders', MAX(order_date), CURRENT_TIMESTAMP FROM staging.orders
UNION ALL
SELECT 'payments', MAX(payment_date), CURRENT_TIMESTAMP FROM staging.payments;

SELECT 'INCREMENTAL LOAD COMPLETE' AS status,
       (SELECT COUNT(*) FROM warehouse.fact_sales)   AS fact_sales_rows,
       (SELECT MAX(order_date) FROM staging.orders)  AS latest_order_date;
