# Blueprint - p05_load_budget

> Concepts Hop (transform, Database Lookup, Run) : `../../docs/apache_hop_concepts.md`.

## Objectif

Charger les donnees de budget dans `warehouse.fact_budget`. Le budget est une
source analytique : comme toutes les autres sources, `sales_budget.csv` transite
d'abord par `staging.budget` (chargement type en `p01`), puis `p05` lit la table
staging, resout les libelles/cles via lookups, et ecrit le fait.

```text
staging.budget
   -> Database Lookup staging.categories  (category_id -> category_name)
   -> Database Lookup warehouse.dim_channel (channel -> channel_key)
   -> Table Output warehouse.fact_budget
```

## Transforms utilises

| Transform | Type | Role |
|-----------|------|------|
| Read staging.budget | TableInput | Lire les lignes de budget typees depuis staging |
| Lookup category name | DatabaseLookup | Resoudre `category_name` depuis `staging.categories` |
| Lookup channel key | DatabaseLookup | Resoudre la cle de substitution `channel_key` depuis `warehouse.dim_channel` |
| Write fact_budget | TableOutput | Ecrire dans `warehouse.fact_budget` (truncate avant chargement) |

## Mapping vers warehouse.fact_budget

| Colonne cible | Source | Note |
|---------------|--------|------|
| budget_id | staging.budget.budget_id | cle naturelle |
| year | staging.budget.year | |
| month_num | staging.budget.month | renomme |
| category_id | staging.budget.category_id | |
| category_name | lookup staging.categories | denormalise (comme dim_product) |
| channel_key | lookup warehouse.dim_channel | cle de substitution (pas de `channel_name`) |
| budget_amount | staging.budget.budget_amount | mesure |
| budget_qty | staging.budget.budget_qty | mesure |
| loaded_at | CURRENT_TIMESTAMP (cote SQL) | |

## Grain

1 ligne par `annee x mois x categorie x canal`. Distinct de `fact_sales`
(grain ligne de commande), d'ou une table de fait separee.

## Dependances

`p05` requiert que `staging.budget` (via `p01`) **et** `warehouse.dim_channel`
(via `p02`) existent. Dans `wf_initial_load`, p05 s'execute apres p02/p03.

## Verifications

```sql
SELECT COUNT(*) FROM warehouse.fact_budget;
-- Attendu : meme nombre de lignes que staging.budget

SELECT COUNT(*) FROM warehouse.fact_budget WHERE channel_key IS NULL;
-- Attendu : 0 (tous les canaux du budget existent dans dim_channel)
```

## Reglages cles par transform (dialogue GUI)

| Transform | Reglages a verifier dans le dialogue |
|-----------|--------------------------------------|
| Database Lookup (channel_key) | Table `warehouse.dim_channel` ; cle de jointure `channel` ; champ retourne `channel_key` ; valeur non trouvee -> NULL (a detecter en verif) |
| Table Output | Connection `DuckDB_Lab1` ; schema `warehouse` ; table `fact_budget` ; Truncate `Y` |

## Pieges courants

- Lancer p05 avant p01 (staging.budget absente) ou avant p02 (dim_channel absente) -> lookups vides.
- Charger `sales_budget.csv` directement dans le fait sans passer par `staging.budget`.

## Notes importantes

- Le SQL equivalent (`sql/41_load_budget.sql`) sert d'oracle de validation et de secours CLI.
- Apres modification dans Hop GUI, re-sauvegardez le fichier pour que le XML soit valide.
