# Lab 1 — Partie A : Ingestion + Exploration (consignes détaillées)

## Scénario métier

Vous travaillez pour une entreprise retail/e-commerce qui vend des produits électroniques et mobilier de bureau. Les données viennent de plusieurs systèmes opérationnels : commandes, clients, produits, paiements et mouvements de stock.

La direction souhaite un premier diagnostic :

- les données sont-elles exploitables pour la BI ?
- quels problèmes de qualité doivent être corrigés ?
- quels KPI peut-on produire de manière fiable ?
- quelles questions métier restent ambiguës ?

## Étape 1 — Ingestion avec Apache Hop

> **Nouveau sur Apache Hop ?** Lire `docs/apache_hop_concepts.md` (projet, pipeline
> vs workflow, transform, exécution Run, connexion DuckDB) avant de commencer.

On construit un **pipeline visuel** plutôt que d'écrire du SQL à la main : chaque
étape (lecture CSV, contrôle, écriture) est explicite et rejouable. La couche
`staging.*` est une **copie typée** des sources (conversion de types, alignement des
colonnes), sans nettoyage métier — celui-ci viendra en Partie B.

> **Deux chemins disponibles**
> - **Chemin officiel (Hop GUI) :** créer et exécuter le pipeline Apache Hop comme décrit ci-dessous.
> - **Alternative CLI (si Hop indisponible) :** exécuter directement `duckdb duckdb/lab1.duckdb ".read sql/01_load_staging_tables.sql"` depuis la racine du lab. Les étapes 2 à 4 sont identiques dans les deux cas.

Créer un pipeline Apache Hop qui :

1. lit les fichiers CSV ;
2. applique un contrôle simple de types ou de colonnes ;
3. charge les données dans une base DuckDB locale ;
4. conserve les noms de tables suivants :

```text
staging.customers
staging.categories
staging.products
staging.orders
staging.order_items
staging.payments
staging.stock_movements
```

Les fichiers `orders_april.csv`, `order_items_april.csv`, `payments_april.csv` et `sales_budget.csv` sont réservés à la Partie B. Ils ne doivent pas être chargés dans les tables `staging.*` principales de la Partie A.

Voir `hop/README_pipeline_apache_hop.md` (guide pas à pas, premier flux `customers`)
et `docs/apache_hop_concepts.md` (concepts de l'outil).

## Étape 2 — Exploration dans DuckDB

Avant de lancer les scripts, parcourez les fichiers `data/raw/` et identifiez les entités métier et leurs relations.

Ouvrir la base DuckDB en mode interactif (depuis le dossier `labs/lab01_hop_duckdb`), puis exécuter les scripts avec `.read` :

```bash
duckdb duckdb/lab1.duckdb
.read sql/02_profile_tables.sql
.read sql/03_quality_checks.sql
```

> Pour quitter la CLI DuckDB : `.quit`

**Résultats obligatoires :**

- nombre de lignes par table ;
- doublons sur les clés supposées ;
- valeurs nulles critiques ;
- ruptures de relations entre tables.

**Aller plus loin (optionnel si le temps le permet) :**

- incohérences de montants ou quantités ;
- premier calcul de chiffre d'affaires (`sql/04_kpi_exploration.sql`) ;
- ventes par mois, canal et catégorie.

> Ces analyses sont reprises en profondeur dans la Partie B sur le schéma en étoile.

## Étape 3 — Rapport qualité initial

Compléter `deliverables/quality_report_template.md` avec **au moins 3 anomalies**.

Pour chaque anomalie :

| Anomalie | Impact métier | Gravité | Correction proposée |
|----------|--------------|---------|---------------------|

## Étape 4 — Premiers KPI

Compléter `deliverables/kpi_list_template.md` avec **3 KPI candidats**.

Pour chaque KPI :

- nom ;
- définition ;
- grain ;
- source ;
- décision que le KPI aide à prendre.

## À réaliser pendant la séance — aucun rendu

Ce lab se fait **en séance**, il n'y a **aucun rendu à remettre**. À la fin de la séance, vous
devriez avoir produit (sur votre poste, pour votre propre usage) :

- le pipeline Apache Hop (ou des captures d'écran) ;
- la base DuckDB locale `duckdb/lab1.duckdb` avec les tables `staging.*` ;
- vos requêtes d'exploration (partez de `sql/05_student_exploration_starter.sql`) ;
- le `deliverables/quality_report_template.md` complété (≥ 3 anomalies) ;
- le `deliverables/kpi_list_template.md` complété (3 KPI candidats).

Servez-vous de `deliverables/checklist_submission.md` comme auto-vérification de fin de séance.


