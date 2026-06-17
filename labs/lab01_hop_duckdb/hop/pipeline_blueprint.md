# Blueprint de pipeline Hop - Reference rapide Partie A

> Resume visuel pour l'ingestion CSV -> `staging.*`.

## Version simple

```text
customers.csv        -> staging.customers
categories.csv       -> staging.categories
products.csv         -> staging.products
orders.csv           -> staging.orders
order_items.csv      -> staging.order_items
payments.csv         -> staging.payments
stock_movements.csv  -> staging.stock_movements
sales_budget.csv     -> staging.budget          # utilise en Partie B
```

## Version avec controles techniques

```text
CSV Input
  -> Select Values / Metadata
  -> Filter Rows (lignes techniquement invalides)
  -> Table Output staging.<table>
  -> Text File Output data/processed/rejects_<table>.csv
```

## Colonnes critiques par table

| Table | Colonnes critiques |
|---|---|
| customers | customer_id, customer_name |
| categories | category_id, category_name |
| products | product_id, category_id, unit_price |
| orders | order_id, customer_id, order_date |
| order_items | order_item_id, order_id, product_id, quantity, unit_price |
| payments | payment_id, order_id, payment_date, amount |
| stock_movements | movement_id, product_id, movement_date, movement_type, quantity |
