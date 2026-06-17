-- sql/31_fact_stock.sql
TRUNCATE warehouse.fact_stock;

INSERT INTO warehouse.fact_stock
    (stock_key, date_key, product_key, qty_in, qty_out, warehouse, loaded_at)
SELECT
    sm.movement_id                                                         AS stock_key,
    dd.date_key,
    dp.product_key,
    CASE sm.movement_type WHEN 'IN'  THEN sm.quantity ELSE 0 END          AS qty_in,
    CASE sm.movement_type WHEN 'OUT' THEN sm.quantity ELSE 0 END          AS qty_out,
    sm.warehouse,
    CURRENT_TIMESTAMP                                                      AS loaded_at
FROM staging.stock_movements    sm
JOIN warehouse.dim_date         dd ON sm.movement_date = dd.date_actual
JOIN warehouse.dim_product      dp ON sm.product_id    = dp.product_id_src
WHERE sm.quantity > 0
  AND sm.movement_type IN ('IN','OUT');
