.read sql/10_create_staging_schema.sql

TRUNCATE staging.customers;
INSERT INTO staging.customers
SELECT
    customer_id::INTEGER,
    customer_name::VARCHAR,
    NULLIF(TRIM(email::VARCHAR), '') AS email,
    city::VARCHAR,
    country::VARCHAR,
    signup_date::DATE,
    segment::VARCHAR
FROM read_csv_auto('data/raw/customers.csv', header=true, nullstr='');

TRUNCATE staging.categories;
INSERT INTO staging.categories
SELECT
    category_id::INTEGER,
    category_name::VARCHAR,
    department::VARCHAR
FROM read_csv_auto('data/raw/categories.csv', header=true, nullstr='');

TRUNCATE staging.products;
INSERT INTO staging.products
SELECT
    product_id::INTEGER,
    product_name::VARCHAR,
    category_id::INTEGER,
    unit_price::DECIMAL(10,2),
    cost_price::DECIMAL(10,2),
    active_flag::INTEGER
FROM read_csv_auto('data/raw/products.csv', header=true, nullstr='');

TRUNCATE staging.orders;
INSERT INTO staging.orders
SELECT
    order_id::INTEGER,
    customer_id::INTEGER,
    order_date::DATE,
    channel::VARCHAR,
    order_status::VARCHAR,
    city::VARCHAR
FROM read_csv_auto('data/raw/orders.csv', header=true, nullstr='');

TRUNCATE staging.order_items;
INSERT INTO staging.order_items
SELECT
    order_item_id::INTEGER,
    order_id::INTEGER,
    product_id::INTEGER,
    quantity::INTEGER,
    unit_price::DECIMAL(10,2),
    discount_amount::DECIMAL(10,2)
FROM read_csv_auto('data/raw/order_items.csv', header=true, nullstr='');

TRUNCATE staging.payments;
INSERT INTO staging.payments
SELECT
    payment_id::INTEGER,
    order_id::INTEGER,
    payment_date::DATE,
    payment_method::VARCHAR,
    payment_status::VARCHAR,
    amount::DECIMAL(10,2)
FROM read_csv_auto('data/raw/payments.csv', header=true, nullstr='');

TRUNCATE staging.stock_movements;
INSERT INTO staging.stock_movements
SELECT
    movement_id::INTEGER,
    product_id::INTEGER,
    movement_date::DATE,
    movement_type::VARCHAR,
    quantity::INTEGER,
    warehouse::VARCHAR
FROM read_csv_auto('data/raw/stock_movements.csv', header=true, nullstr='');

TRUNCATE staging.budget;
INSERT INTO staging.budget
SELECT
    budget_id::INTEGER,
    year::INTEGER,
    month::INTEGER,
    category_id::INTEGER,
    channel::VARCHAR,
    budget_amount::DECIMAL(10,2),
    budget_qty::INTEGER
FROM read_csv_auto('data/raw/sales_budget.csv', header=true, nullstr='');
