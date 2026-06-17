-- sql/23_dim_product.sql
INSERT INTO warehouse.dim_product
    (product_key, product_id_src, product_name, category_id, category_name,
     department, unit_price, cost_price, active_flag, loaded_at)
SELECT
    ROW_NUMBER() OVER (ORDER BY product_id)        AS product_key,
    p.product_id                                   AS product_id_src,
    p.product_name,
    p.category_id,
    c.category_name,
    c.department,
    p.unit_price,
    p.cost_price,
    p.active_flag,
    CURRENT_TIMESTAMP                              AS loaded_at
FROM staging.products p
LEFT JOIN staging.categories c ON p.category_id = c.category_id
WHERE p.product_id IS NOT NULL;
