-- PremiÃ¨res explorations KPI â€” Lab 1

-- CA net thÃ©orique par ligne, hors commandes annulÃ©es et retournÃ©es.
WITH sales_lines AS (
  SELECT
    o.order_id,
    o.order_date,
    DATE_TRUNC('month', o.order_date)::DATE AS order_month,
    o.channel,
    o.order_status,
    oi.product_id,
    p.product_name,
    c.category_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_amount,
    oi.quantity * oi.unit_price AS gross_amount,
    oi.quantity * oi.unit_price - oi.discount_amount AS net_amount
  FROM staging.orders o
  JOIN staging.order_items oi ON o.order_id = oi.order_id
  LEFT JOIN staging.products p ON oi.product_id = p.product_id
  LEFT JOIN staging.categories c ON p.category_id = c.category_id
  WHERE o.order_status = 'Completed'
)
SELECT
  SUM(gross_amount) AS gross_revenue,
  SUM(net_amount) AS net_revenue,
  COUNT(DISTINCT order_id) AS completed_orders,
  SUM(net_amount) / NULLIF(COUNT(DISTINCT order_id), 0) AS average_order_value
FROM sales_lines;

-- Ventes par mois
WITH sales_lines AS (
  SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS order_month,
    oi.quantity * oi.unit_price - oi.discount_amount AS net_amount,
    o.order_id
  FROM staging.orders o
  JOIN staging.order_items oi ON o.order_id = oi.order_id
  WHERE o.order_status = 'Completed'
)
SELECT
  order_month,
  COUNT(DISTINCT order_id) AS completed_orders,
  SUM(net_amount) AS net_revenue
FROM sales_lines
GROUP BY order_month
ORDER BY order_month;

-- Ventes par canal
SELECT
  o.channel,
  COUNT(DISTINCT o.order_id) AS completed_orders,
  SUM(oi.quantity * oi.unit_price - oi.discount_amount) AS net_revenue
FROM staging.orders o
JOIN staging.order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY o.channel
ORDER BY net_revenue DESC;

-- Ventes par catÃ©gorie
SELECT
  COALESCE(c.category_name, 'UNKNOWN') AS category_name,
  COUNT(DISTINCT o.order_id) AS completed_orders,
  SUM(oi.quantity * oi.unit_price - oi.discount_amount) AS net_revenue
FROM staging.orders o
JOIN staging.order_items oi ON o.order_id = oi.order_id
LEFT JOIN staging.products p ON oi.product_id = p.product_id
LEFT JOIN staging.categories c ON p.category_id = c.category_id
WHERE o.order_status = 'Completed'
GROUP BY COALESCE(c.category_name, 'UNKNOWN')
ORDER BY net_revenue DESC;

-- Retours et annulations par statut
SELECT
  order_status,
  COUNT(*) AS orders_count
FROM staging.orders
GROUP BY order_status
ORDER BY orders_count DESC;

-- Impact des remises
SELECT
  SUM(quantity * unit_price) AS gross_amount,
  SUM(discount_amount) AS total_discount,
  SUM(quantity * unit_price - discount_amount) AS net_amount,
  SUM(discount_amount) / NULLIF(SUM(quantity * unit_price), 0) AS discount_rate
FROM staging.order_items;

