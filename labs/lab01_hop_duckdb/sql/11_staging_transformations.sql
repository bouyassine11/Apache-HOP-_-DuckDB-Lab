-- sql/11_staging_transformations.sql
-- SQL oracle notes for the classic BI ETL version of Lab 1.
--
-- In the main path, Apache Hop loads CSV files directly into staging.* as
-- typed landing tables. Business transformations happen when Hop loads
-- warehouse.*. This file is intentionally non-mutating: use it to inspect
-- what the warehouse load must handle, not as the primary transformation path.

SELECT 'duplicate_customers' AS check_name,
       COUNT(*) AS issue_count
FROM (
    SELECT customer_id
    FROM staging.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) d;

SELECT 'customer_city_variants' AS check_name,
       UPPER(TRIM(city)) AS normalized_probe,
       COUNT(*) AS rows_seen
FROM staging.customers
GROUP BY UPPER(TRIM(city))
ORDER BY rows_seen DESC;

SELECT 'orphan_orders' AS check_name,
       COUNT(*) AS issue_count
FROM staging.orders o
LEFT JOIN staging.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT 'invalid_order_items' AS check_name,
       COUNT(*) AS issue_count
FROM staging.order_items
WHERE quantity <= 0 OR unit_price < 0;
