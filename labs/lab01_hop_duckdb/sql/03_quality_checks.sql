-- ContrÃ´les qualitÃ© initiaux â€” Lab 1

-- 1. Doublons de clÃ©s supposÃ©es uniques
SELECT 'customers.customer_id duplicate' AS check_name, customer_id AS key_value, COUNT(*) AS issue_count
FROM staging.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT 'orders.order_id duplicate' AS check_name, order_id AS key_value, COUNT(*) AS issue_count
FROM staging.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT 'order_items.order_item_id duplicate' AS check_name, order_item_id AS key_value, COUNT(*) AS issue_count
FROM staging.order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1;

SELECT 'payments.payment_id duplicate' AS check_name, payment_id AS key_value, COUNT(*) AS issue_count
FROM staging.payments
GROUP BY payment_id
HAVING COUNT(*) > 1;

-- 2. Valeurs nulles critiques
SELECT 'customers.email null' AS check_name, COUNT(*) AS issue_count
FROM staging.customers
WHERE email IS NULL OR email = '';

SELECT 'orders.customer_id null' AS check_name, COUNT(*) AS issue_count
FROM staging.orders
WHERE customer_id IS NULL;

SELECT 'order_items.product_id null' AS check_name, COUNT(*) AS issue_count
FROM staging.order_items
WHERE product_id IS NULL;

-- 3. Relations cassÃ©es
SELECT 'orders without customer' AS check_name, o.order_id, o.customer_id
FROM staging.orders o
LEFT JOIN staging.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT 'order_items without order' AS check_name, oi.order_item_id, oi.order_id
FROM staging.order_items oi
LEFT JOIN staging.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT 'order_items without product' AS check_name, oi.order_item_id, oi.product_id
FROM staging.order_items oi
LEFT JOIN staging.products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT 'payments without order' AS check_name, p.payment_id, p.order_id
FROM staging.payments p
LEFT JOIN staging.orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT 'stock movements without product' AS check_name, sm.movement_id, sm.product_id
FROM staging.stock_movements sm
LEFT JOIN staging.products p ON sm.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 4. Valeurs numÃ©riques suspectes
SELECT 'products with non-positive active unit_price' AS check_name, product_id, product_name, unit_price, active_flag
FROM staging.products
WHERE active_flag = 1 AND unit_price <= 0;

SELECT 'order_items with non-positive quantity' AS check_name, order_item_id, order_id, product_id, quantity
FROM staging.order_items
WHERE quantity <= 0;

SELECT 'order_items with negative discount' AS check_name, order_item_id, discount_amount
FROM staging.order_items
WHERE discount_amount < 0;

SELECT 'payments with negative amount' AS check_name, payment_id, order_id, amount
FROM staging.payments
WHERE amount < 0;

-- 5. Comparaison montant lignes vs paiement par commande
WITH order_line_amounts AS (
  SELECT
    order_id,
    SUM(quantity * unit_price - discount_amount) AS line_net_amount
  FROM staging.order_items
  GROUP BY order_id
), payment_amounts AS (
  SELECT
    order_id,
    SUM(amount) AS paid_amount
  FROM staging.payments
  WHERE payment_status IN ('Paid', 'Pending')
  GROUP BY order_id
)
SELECT
  o.order_id,
  o.order_status,
  ola.line_net_amount,
  pa.paid_amount,
  pa.paid_amount - ola.line_net_amount AS difference
FROM staging.orders o
LEFT JOIN order_line_amounts ola ON o.order_id = ola.order_id
LEFT JOIN payment_amounts pa ON o.order_id = pa.order_id
ORDER BY ABS(COALESCE(pa.paid_amount, 0) - COALESCE(ola.line_net_amount, 0)) DESC;

