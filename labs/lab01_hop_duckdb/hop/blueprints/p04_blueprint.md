# Blueprint - p04_incremental_load

> Concepts Hop (pipeline vs workflow, transform, Run) : `../../docs/apache_hop_concepts.md`.
> Pattern watermark (rationale) : `../../docs/incremental_load_pattern.md`.

## Objectif

Charger le batch d'avril 2025 dans `staging.*` avec le pattern watermark, puis laisser `p03_build_facts` reconstruire les faits depuis staging et les dimensions.

## Flow Hop attendu

```text
[Read orders_april.csv]
  -> Select Values (types)
  -> Filter Rows (order_date > watermark)
  -> Database Lookup staging.orders (dedup order_id)
  -> Table Output staging.orders

[Read order_items_april.csv]
  -> Select Values (types)
  -> Database Lookup staging.order_items (dedup order_item_id)
  -> Table Output staging.order_items

[Read payments_april.csv]
  -> Select Values (types)
  -> Filter Rows (payment_date > payments watermark)
  -> Database Lookup staging.payments (dedup payment_id)
  -> Table Output staging.payments

[Update watermarks]
```

`ExecSql` est acceptable uniquement pour lire ou mettre a jour `control.load_watermark`. Les imports CSV, conversions de types et controles de doublons doivent etre visibles avec des transforms Hop natifs.

## Watermarks

```sql
SELECT COALESCE(MAX(last_load_dt), DATE '2000-01-01')
FROM control.load_watermark
WHERE table_name = 'orders';
```

Appliquer le meme principe pour `payments`.

## Verification apres execution

```sql
SELECT order_date, COUNT(*)
FROM staging.orders
WHERE order_date >= '2025-04-01'
GROUP BY order_date
ORDER BY order_date;

SELECT * FROM control.load_watermark ORDER BY table_name;
-- Attendu : orders -> 2025-04-20, payments -> 2025-04-21

SELECT COUNT(*) FROM warehouse.fact_sales;
-- Attendu apres p03 : 19
```

## Reglages cles par transform (dialogue GUI)

| Transform | Reglages a verifier dans le dialogue |
|-----------|--------------------------------------|
| CSV Input | Filename `${DATA_DIR}/orders_april.csv` (idem order_items_april / payments_april) ; memes types que le chargement initial |
| Filter Rows | Condition `order_date > watermark` (resp. `payment_date > watermark`) pour ne garder que le nouveau batch |
| Database Lookup | Sur `staging.orders` / `staging.order_items` / `staging.payments` par cle naturelle ; sert a ecarter les doublons deja charges |
| Table Output | Connection `DuckDB_Lab1` ; schema `staging` ; **Truncate `N`** (append du batch, pas de remise a zero) |

## Pieges courants

- Mettre Truncate `Y` sur le Table Output staging : on efface l'historique au lieu d'ajouter le batch.
- Oublier de mettre a jour `control.load_watermark` : le batch est rejoue au prochain Run.
- Croire que p04 reconstruit les faits : non, c'est `wf_incremental_load.hwf` qui enchaine p03 ensuite.

## Note

`p04_incremental_load` charge seulement les nouvelles lignes typees dans staging et met a jour les watermarks. Le workflow `wf_incremental_load.hwf` enchaine ensuite `p03_build_facts` pour appliquer les regles warehouse.
