-- Profiling rapide des tables staging

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM staging.customers
UNION ALL SELECT 'categories', COUNT(*) FROM staging.categories
UNION ALL SELECT 'products', COUNT(*) FROM staging.products
UNION ALL SELECT 'orders', COUNT(*) FROM staging.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM staging.order_items
UNION ALL SELECT 'payments', COUNT(*) FROM staging.payments
UNION ALL SELECT 'stock_movements', COUNT(*) FROM staging.stock_movements
ORDER BY table_name;

-- PÃ©riode couverte par les commandes
SELECT
  MIN(order_date) AS first_order_date,
  MAX(order_date) AS last_order_date,
  COUNT(DISTINCT order_id) AS orders_count
FROM staging.orders;

-- Distribution des statuts commande
SELECT order_status, COUNT(*) AS orders_count
FROM staging.orders
GROUP BY order_status
ORDER BY orders_count DESC;

-- Distribution des canaux
SELECT channel, COUNT(*) AS orders_count
FROM staging.orders
GROUP BY channel
ORDER BY orders_count DESC;

-- Distribution des mÃ©thodes de paiement
SELECT payment_method, payment_status, COUNT(*) AS payments_count, SUM(amount) AS total_amount
FROM staging.payments
GROUP BY payment_method, payment_status
ORDER BY payment_method, payment_status;

