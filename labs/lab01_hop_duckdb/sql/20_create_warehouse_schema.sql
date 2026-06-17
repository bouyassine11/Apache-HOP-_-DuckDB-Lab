-- sql/20_create_warehouse_schema.sql

CREATE SCHEMA IF NOT EXISTS warehouse;

-- DIMENSIONS
CREATE OR REPLACE TABLE warehouse.dim_date (
    date_key     INTEGER PRIMARY KEY,  -- YYYYMMDD computed integer
    date_actual  DATE,
    year         INTEGER,
    quarter      INTEGER,
    month_num    INTEGER,
    month_name   VARCHAR,
    day_num      INTEGER,
    day_name     VARCHAR,
    day_of_week  INTEGER,             -- 0=Sunday ... 6=Saturday (DuckDB convention)
    is_weekend   BOOLEAN,
    season       VARCHAR
);

CREATE OR REPLACE TABLE warehouse.dim_customer (
    customer_key    INTEGER PRIMARY KEY,
    customer_id_src INTEGER,
    customer_name   VARCHAR,
    email           VARCHAR,
    city            VARCHAR,
    country         VARCHAR,
    signup_date     DATE,
    segment         VARCHAR,
    loaded_at       TIMESTAMP
);

CREATE OR REPLACE TABLE warehouse.dim_product (
    product_key    INTEGER PRIMARY KEY,
    product_id_src INTEGER,
    product_name   VARCHAR,
    category_id    INTEGER,
    category_name  VARCHAR,
    department     VARCHAR,
    unit_price     DECIMAL(10,2),
    cost_price     DECIMAL(10,2),
    active_flag    INTEGER,
    loaded_at      TIMESTAMP
);

CREATE OR REPLACE TABLE warehouse.dim_channel (
    channel_key  INTEGER PRIMARY KEY,
    channel_name VARCHAR UNIQUE,        -- joined as a text key by the facts
    channel_type VARCHAR
);

-- FACTS
CREATE OR REPLACE TABLE warehouse.fact_sales (
    sales_key         INTEGER PRIMARY KEY,  -- warehouse surrogate
    order_item_id_src INTEGER,              -- staging natural key (traceability)
    date_key        INTEGER,
    customer_key    INTEGER,
    product_key     INTEGER,
    channel_key     INTEGER,
    order_id        INTEGER,
    quantity        INTEGER,
    sale_unit_price DECIMAL(10,2),
    cost_unit_price DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    gross_amount    DECIMAL(10,2),
    net_amount      DECIMAL(10,2),
    cost_amount     DECIMAL(10,2),
    margin_amount   DECIMAL(10,2),
    order_status    VARCHAR,
    loaded_at       TIMESTAMP
);

CREATE OR REPLACE TABLE warehouse.fact_stock (
    stock_key   INTEGER PRIMARY KEY,
    date_key    INTEGER,
    product_key INTEGER,
    qty_in      INTEGER,
    qty_out     INTEGER,
    warehouse   VARCHAR,
    loaded_at   TIMESTAMP
);

CREATE OR REPLACE TABLE warehouse.fact_budget (
    budget_id     INTEGER PRIMARY KEY,
    year          INTEGER,
    month_num     INTEGER,
    category_id   INTEGER,
    category_name VARCHAR,
    channel_key   INTEGER,
    budget_amount DECIMAL(10,2),
    budget_qty    INTEGER,
    loaded_at     TIMESTAMP
);
