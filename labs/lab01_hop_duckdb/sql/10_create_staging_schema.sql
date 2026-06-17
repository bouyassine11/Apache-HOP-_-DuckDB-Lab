-- sql/10_create_staging_schema.sql

CREATE SCHEMA IF NOT EXISTS staging;

CREATE OR REPLACE TABLE staging.customers (
    customer_id   INTEGER,
    customer_name VARCHAR,
    email         VARCHAR,
    city          VARCHAR,
    country       VARCHAR,
    signup_date   DATE,
    segment       VARCHAR
);

CREATE OR REPLACE TABLE staging.categories (
    category_id   INTEGER,
    category_name VARCHAR,
    department    VARCHAR
);

CREATE OR REPLACE TABLE staging.products (
    product_id    INTEGER,
    product_name  VARCHAR,
    category_id   INTEGER,
    unit_price    DECIMAL(10,2),
    cost_price    DECIMAL(10,2),
    active_flag   INTEGER
);

CREATE OR REPLACE TABLE staging.orders (
    order_id      INTEGER,
    customer_id   INTEGER,
    order_date    DATE,
    channel       VARCHAR,
    order_status  VARCHAR,
    city          VARCHAR
);

CREATE OR REPLACE TABLE staging.order_items (
    order_item_id   INTEGER,
    order_id        INTEGER,
    product_id      INTEGER,
    quantity        INTEGER,
    unit_price      DECIMAL(10,2),
    discount_amount DECIMAL(10,2)
);

CREATE OR REPLACE TABLE staging.payments (
    payment_id      INTEGER,
    order_id        INTEGER,
    payment_date    DATE,
    payment_method  VARCHAR,
    payment_status  VARCHAR,
    amount          DECIMAL(10,2)
);

CREATE OR REPLACE TABLE staging.stock_movements (
    movement_id    INTEGER,
    product_id     INTEGER,
    movement_date  DATE,
    movement_type  VARCHAR,
    quantity       INTEGER,
    warehouse      VARCHAR
);

CREATE OR REPLACE TABLE staging.budget (
    budget_id     INTEGER,
    year          INTEGER,
    month         INTEGER,
    category_id   INTEGER,
    channel       VARCHAR,
    budget_amount DECIMAL(10,2),
    budget_qty    INTEGER
);
