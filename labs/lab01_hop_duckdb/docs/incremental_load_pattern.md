# Pattern de chargement incremental - Lab 1

## Le probleme

Apres le chargement initial, de nouvelles donnees arrivent regulierement. Ici, le batch d'avril 2025 doit etre integre sans recharger manuellement tous les CSV historiques.

## La table watermark

```sql
-- control.load_watermark
table_name      VARCHAR PRIMARY KEY
last_load_dt    DATE
updated_at      TIMESTAMP
```

Le watermark stocke la date maximale connue dans `staging.*`. Le prochain chargement incremental filtre les fichiers batch avec `date > last_load_dt`.

```sql
SELECT COALESCE(MAX(last_load_dt), DATE '2000-01-01')
FROM control.load_watermark
WHERE table_name = 'orders';
```

## Idempotence

Le pipeline Hop doit eviter les doublons techniques lors d'une reexecution :

```text
batch CSV
  -> Select Values (types)
  -> Filter Rows (date > watermark)
  -> Database Lookup staging.<table> on natural key
  -> keep only lookup misses
  -> Table Output staging.<table>
```

Dans le chemin SQL de secours, le meme principe est exprime avec `NOT EXISTS`.

## Pourquoi fact_sales fait un TRUNCATE + rechargement complet

Dans ce lab, `fact_sales` est recalculee entierement apres chaque chargement incremental. Ce choix simplifie le raisonnement pedagogique, evite les problemes de cles de substitution orphelines et reste acceptable pour un petit jeu de donnees.

En production, on utiliserait plus souvent un `MERGE` ou un pattern d'upsert.

## Pieges courants

### Paiements en retard

Un paiement peut arriver apres la commande. Le watermark de `payments` doit donc rester independant de celui de `orders`.

### Commandes annulees

La commande `1019` dans `orders_april.csv` a le statut `Cancelled`. Elle est chargee dans `staging.orders`. La decision de l'inclure ou de l'exclure des indicateurs se prend au niveau warehouse ou dans les requetes analytiques.

### Reinitialisation

Si `50_initial_full_load.sql` est relance, le warehouse et les watermarks sont reconstruits. Le prochain incremental repart de la date maximale chargee.

## Sequence d'execution incrementale

```text
1. Lire orders_april.csv, order_items_april.csv, payments_april.csv
2. Convertir les types et aligner les schemas
3. Filtrer les lignes selon les watermarks orders/payments
4. Eviter les doublons techniques dans staging
5. Inserer les nouvelles lignes dans staging.*
6. Reconstruire warehouse.fact_sales via p03
7. Mettre a jour control.load_watermark
```
