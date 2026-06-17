# Lab 1 — Partie B : ETL classique, modélisation & chargement

Cette partie prolonge la Partie A. Elle suppose que les sources principales ont été comprises, que la base DuckDB locale est utilisable, et que les tables `staging.*` peuvent être recréées avec `sql/01_load_staging_tables.sql`.

## Pré-requis Hop

> **Nouveau sur Hop ?** Voir `docs/apache_hop_concepts.md` pour les concepts de
> l'outil (projet, pipeline `.hpl` vs workflow `.hwf`, transform, Run, connexion).

1. Ouvrir Apache Hop → **File → New Project**
2. **Project Home** = chemin absolu du dossier `labs/lab01_hop_duckdb`
3. La connexion `DuckDB_Lab1` est déjà définie dans `hop/metadata/rdbms/DuckDB_Lab1.json`
4. Télécharger `duckdb-jdbc-*.jar` depuis `duckdb.org` et le copier dans le dossier `lib/` du projet Hop
5. Vérifier la connexion : clic droit sur `DuckDB_Lab1` → **Test connection**

> La variable `${HOP_PROJECT_HOME}` est automatiquement résolue par Hop au chemin du projet. Le fichier DuckDB est à `duckdb/lab1.duckdb` dans ce dossier.

## Architecture des couches

```text
data/raw/      (CSV sources)
      -> Hop native ETL
staging.*      (tables typées, landing : copie minimale des CSV)
      -> Hop native ETL
warehouse.*    (dimensions, faits, budget : données nettoyées et conformées)
control.*      (watermarks de chargement, log)
```

`staging.*` n'est pas une couche métier nettoyée. Elle sert de zone d'atterrissage typée : conversion de types, alignement de schéma, rejets techniques si une ligne est illisible. La déduplication, la normalisation, les jointures, les filtres métier, le mapping des clés de substitution et les calculs de mesures se font pendant les chargements `warehouse.*`.

Les scripts SQL restent disponibles comme oracle de validation et chemin de secours CLI. Le workflow principal à construire dans Hop doit utiliser des transforms Hop natifs, pas des transformations SQL `INSERT ... SELECT`.

## Objectifs et livrables

### Partie B-1 — Couche staging (30 min)

Charger les CSV principaux directement dans `staging.*` avec Apache Hop.

**Chemin Hop attendu :** `CSV Input -> Select Values / Metadata -> contrôles techniques -> Table Output`.

Tables attendues :

```text
staging.customers
staging.categories
staging.products
staging.orders
staging.order_items
staging.payments
staging.stock_movements
```

> Le budget (`sales_budget.csv`) est également chargé en staging (`staging.budget`) selon le même principe ; il est utilisé en Partie B-5.

Règles autorisées en staging :

- conversion de types ;
- alignement des colonnes ;
- rejet technique des lignes illisibles ou sans identifiant obligatoire ;
- déduplication uniquement si elle est nécessaire pour éviter un échec de chargement.

Règles à ne pas appliquer en staging :

- normalisation des villes ;
- filtrage métier des statuts de commande ;
- suppression des références orphelines ;
- enrichissement produit avec les catégories ;
- calcul de mesures.

**Questions d'analyse :**
1. Combien de lignes sont chargées dans chaque table `staging.*` ?
2. Quelles anomalies restent visibles dans staging et devront être traitées au chargement warehouse ?

### Partie B-2 — Modèle en étoile (30 min)

Construire le data warehouse dimensionnel depuis `staging.*` vers `warehouse.*` avec des transforms Hop natifs.

Règles appliquées pendant les chargements warehouse :

- Clients : déduplication sur `customer_id`, normalisation des noms de villes, valeur email par défaut si manquante
- Produits : enrichissement avec `category_name` et `department` depuis `staging.categories`
- Commandes : exclusion des références clients orphelines et des statuts invalides lors du chargement des faits
- Lignes de commandes : exclusion des références orphelines, `quantity > 0`, `unit_price >= 0`
- Mouvements de stock : `movement_type IN ('IN','OUT')`, références produits valides
- Faits : mapping vers les clés de substitution et calcul de `gross_amount`, `net_amount`, `cost_amount`, `margin_amount`

> `fact_sales.sales_key` est une clé de substitution générée dans le warehouse ; la clé naturelle `order_item_id` est conservée comme `order_item_id_src`.

**Oracle SQL :** `sql/20_create_warehouse_schema.sql` + `sql/21_dim_date.sql` à `sql/31_fact_stock.sql`.

Voir `docs/star_schema_design.md` pour l'ERD complet et les définitions de grain.

**Questions d'analyse :**
1. Quelle est la granularité de `fact_sales` ? de `fact_stock` ?
2. Pourquoi utilise-t-on des clés de substitution (`customer_key`) plutôt que les IDs sources ?

### Partie B-3 — Chargement initial (20 min)

**Chemin Hop (principal) :** ouvrir `hop/workflows/wf_initial_load.hwf` dans Hop GUI et l'exécuter (Run). Le workflow orchestre `p01 → p02 → p03 → p05`. Vérifier que toutes les actions passent au vert.

> **Ordre d'exécution :** lancer les scripts dans l'ordre `50` → `51` → `52`, une seule fois chacun.
> Ne pas relancer `50_initial_full_load.sql` après `51` : il réinitialise le warehouse et le watermark.

Chemin de secours CLI :

```bash
duckdb duckdb/lab1.duckdb ".read sql/50_initial_full_load.sql"
```

**Résultat attendu :**

```text
FULL LOAD COMPLETE | fact_sales_rows=13 | fact_stock_rows=10 | fact_budget_rows=12 | latest_order_date=2025-03-21
```

Validations :

```sql
SELECT COUNT(*) FROM warehouse.fact_sales
WHERE date_key IS NULL OR customer_key IS NULL OR product_key IS NULL;
-- Attendu : 0

SELECT COUNT(*) FROM staging.orders o
LEFT JOIN warehouse.dim_date dd ON o.order_date = dd.date_actual
WHERE dd.date_key IS NULL;
-- Attendu : 0

SELECT COUNT(*) FROM warehouse.fact_budget;
-- Attendu : 12
```

### Partie B-4 — Chargement incrémental (30 min)

Simuler l'arrivée d'un nouveau batch (commandes d'avril 2025).

Le watermark `control.load_watermark` stocke la date du dernier chargement. Le pipeline incrémental ajoute les lignes typées dans `staging.*`, puis reconstruit les faits concernés.

**Chemin Hop (principal) :** ouvrir `hop/workflows/wf_incremental_load.hwf` dans Hop GUI et l'exécuter (Run). Le workflow orchestre `p04 → p03` (rebuild des faits).

Chemin de secours CLI :

```bash
duckdb duckdb/lab1.duckdb ".read sql/51_incremental_load.sql"
```

**Résultat attendu :**

```text
INCREMENTAL LOAD COMPLETE | fact_sales_rows=19 | latest_order_date=2025-04-20
```

Le batch d'avril ajoute 5 commandes dans `staging.orders`, et 6 lignes supplémentaires dans `warehouse.fact_sales` après application des règles warehouse.

Voir `docs/incremental_load_pattern.md` pour les détails du pattern et les pièges.

**Questions d'analyse :**
1. Combien de lignes ont été ajoutées dans `staging.orders` ?
2. Pourquoi `fact_sales` fait-il un `TRUNCATE` + rechargement complet plutôt qu'un append ?

### Partie B-5 — Budget vs réalisé (20 min)

Comparer les ventes réelles aux objectifs budgétaires. Le budget transite par `staging.budget` puis est chargé dans `warehouse.fact_budget` (pipeline `p05`).

```bash
duckdb duckdb/lab1.duckdb ".read sql/52_actuals_vs_budget.sql"
```

**Questions d'analyse :**
1. Quel mois/catégorie a le meilleur taux d'atteinte du budget ?
2. Que signifie un `achievement_pct` NULL ?

### Partie B-6 — Pipelines Hop (60 min)

Construire visuellement les pipelines Hop :

- `p01_csv_to_staging` : CSV → `staging.*`
- `p02_build_dims` : `staging.*` → dimensions `warehouse.*`
- `p03_build_facts` : `staging.*` + dimensions → faits
- `p04_incremental_load` : batch avril → `staging.*` + watermarks
- `p05_load_budget` : `staging.budget` → `warehouse.fact_budget`

Ces pipelines sont orchestrés par les workflows `hop/workflows/wf_initial_load.hwf` (chargement complet) et `hop/workflows/wf_incremental_load.hwf` (chargement incrémental), exécutés en Parties B-3 et B-4.

> **Pipeline vs workflow :** un *pipeline* (`.hpl`) transforme un flux de données ;
> un *workflow* (`.hwf`) orchestre l'ordre d'exécution des pipelines. Détails dans
> `docs/apache_hop_concepts.md`.

`ExecSql` est autorisé uniquement pour le plumbing : création de schéma/table, `TRUNCATE`, initialisation ou mise à jour de `control.*`. La logique de transformation doit être exprimée avec des transforms Hop tels que `CSV Input`, `Select Values`, `Filter Rows`, `Value Mapper`, `Calculator`, `Database Lookup`, `Merge Join`, `Unique Rows`, `Add Sequence`, `Table Output`.

## À produire pendant la séance (non rendu)

- [ ] le pipeline `p01_csv_to_staging` complété dans Hop GUI ;
- [ ] les pipelines warehouse construits avec transforms Hop natifs ;
- [ ] le workflow `wf_initial_load` exécuté avec succès ;
- [ ] le résultat de la requête `52_actuals_vs_budget.sql` ;
- [ ] vos réponses aux questions d'analyse des parties B-1 à B-5.

## Ressources

| Fichier | Description |
|---------|-------------|
| `docs/apache_hop_concepts.md` | Concepts de l'outil Hop (projet, pipeline/workflow, transform, Run) |
| `sql/50_initial_full_load.sql` | Oracle CLI de chargement complet |
| `docs/star_schema_design.md` | ERD et définitions de grain |
| `docs/incremental_load_pattern.md` | Pattern watermark et pièges |
| `hop/blueprints/p01_blueprint.md` | Guide pour CSV → staging |
| `hop/blueprints/p02_p03_blueprint.md` | Guide Hop natif pour dimensions et faits |
| `hop/blueprints/p04_blueprint.md` | Guide pour le chargement incrémental |
| `hop/blueprints/p05_blueprint.md` | Guide pour le chargement du budget |
