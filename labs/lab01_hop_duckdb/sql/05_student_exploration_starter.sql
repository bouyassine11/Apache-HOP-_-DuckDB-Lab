-- Starter SQL Ã©tudiant â€” complÃ©ter librement

-- 1. Choisissez une table et affichez 10 lignes.
SELECT *
FROM staging.orders
LIMIT 10;

-- 2. VÃ©rifiez une clÃ© unique.
SELECT
  order_id,
  COUNT(*) AS n
FROM staging.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3. Construisez votre propre KPI.
-- Exemple : CA par ville.
SELECT
  o.city,
  SUM(oi.quantity * oi.unit_price - oi.discount_amount) AS net_revenue
FROM staging.orders o
JOIN staging.order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY o.city
ORDER BY net_revenue DESC;

