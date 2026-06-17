# Apache Hop — concepts de l'outil (Lab 1)

> **À lire avant de construire un pipeline.** Ce document explique **la mécanique
> d'Apache Hop en tant qu'outil**. Il ne redéfinit pas l'architecture des données
> du lab : pour le « pourquoi » des couches (`staging` vs `warehouse`), des clés de
> substitution ou des watermarks, voir les ressources listées en bas de page.

## 1. Le projet Hop

Apache Hop travaille toujours dans un **projet**. Un projet est simplement un
dossier sur disque + sa configuration.

- **File → New Project**
- **Project Home** = le chemin absolu du dossier `labs/lab01_hop_duckdb`.

Une fois le projet ouvert, Hop expose deux variables utiles :

- `${HOP_PROJECT_HOME}` : résolu automatiquement au chemin du projet (le dossier du
  lab). Le fichier DuckDB est donc à `duckdb/lab1.duckdb` relativement à ce dossier.
- `${DATA_DIR}` : paramètre défini dans les pipelines du lab, par défaut `data/raw`.
  Les transforms de lecture CSV pointent vers `${DATA_DIR}/customers.csv`, etc.
  plutôt que d'écrire un chemin absolu en dur.

> **Conséquence pratique :** si vous ouvrez les `.hpl`/`.hwf` fournis sans définir
> le Project Home sur le dossier du lab, les chemins relatifs et la connexion ne se
> résolvent pas. C'est la cause d'erreur n°1 au démarrage.

## 2. Pipeline vs Workflow

Apache Hop distingue deux objets, et la confusion entre les deux est fréquente.

| Objet | Extension | Contient | Question à se poser |
|-------|-----------|----------|---------------------|
| **Pipeline** | `.hpl` | un flux de **données** ligne par ligne (transforms reliés) | « comment transformer ces lignes ? » |
| **Workflow** | `.hwf` | une **orchestration d'actions** (lancer un pipeline, un SQL, un check) | « dans quel ordre lancer les étapes ? » |

Dans le Lab 1 :

- Les **pipelines** sont `hop/pipelines/p01..p05` : chacun lit, transforme et écrit
  des lignes (CSV → `staging.*`, `staging.*` → `warehouse.*`, etc.).
- Les **workflows** sont `hop/workflows/wf_initial_load.hwf` et
  `wf_incremental_load.hwf` : ils ne transforment aucune ligne eux-mêmes, ils
  **enchaînent** les pipelines (`p01 → p02 → p03 → p05` pour le chargement complet).

Image mentale : le **pipeline** est une chaîne de montage ; le **workflow** est le
chef d'atelier qui décide quelle chaîne démarre, et dans quel ordre.

## 3. Transform et hop

À l'intérieur d'un pipeline :

- un **transform** (parfois appelé « step ») est une boîte sur le canvas qui fait
  une opération sur le flux : lire un CSV (`CSV Input`), filtrer (`Filter Rows`),
  enrichir (`Database Lookup`), calculer (`Calculator`), écrire (`Table Output`)…
- un **hop** est la **flèche** qui relie deux transforms : il fait circuler les
  lignes de l'un vers l'autre. (C'est de là que l'outil tire son nom.)

Certains transforms ont **plusieurs sorties** : un `Filter Rows` a une sortie
« true » et une sortie « false ». Le hop transporte alors les lignes valides d'un
côté et les rejets de l'autre.

## 4. Lire le canvas et exécuter (Run)

- Le **canvas** est la zone centrale où l'on dépose et relie les transforms.
- Pour ajouter un transform : double-clic sur le canvas (ou recherche) puis on le
  relie en tirant un hop depuis le bord d'un transform existant.
- Pour exécuter : bouton **Run** (en haut). Hop affiche alors, **transform par
  transform**, le nombre de lignes lues / écrites et un état visuel :
  - **vert** = succès,
  - **rouge** = erreur (cliquer pour lire le log).
- Les **compteurs de lignes** entre chaque transform sont l'outil de débogage
  principal : si un compteur tombe à 0 là où vous attendiez des lignes, le problème
  est dans le transform précédent (souvent un `Filter Rows` ou un `Database Lookup`
  qui ne matche pas).

> Pour un **workflow**, Run enchaîne les actions ; chaque action (chaque pipeline)
> passe au vert ou au rouge. Tout doit être vert.

## 5. La connexion DuckDB

Les transforms qui touchent la base (`Table Input`, `Table Output`,
`Database Lookup`) utilisent une **connexion** nommée.

- La connexion `DuckDB_Lab1` est **déjà définie** dans
  `hop/metadata/rdbms/DuckDB_Lab1.json` et pointe vers `duckdb/lab1.duckdb`.
- Elle a besoin du **driver JDBC DuckDB** (`duckdb-jdbc-*.jar`) copié dans le
  dossier `lib/` du projet Hop. Sans ce `.jar`, le **Test connection** échoue.
- Vérification : clic droit sur `DuckDB_Lab1` → **Test connection**.

Les détails d'installation (driver, `lib/`, test) sont rappelés dans les pré-requis
de `lab01_part_b_consignes.md`.

## 6. Transform natif vs SQL

Le chemin principal du lab est **Hop natif** : la logique (filtres, jointures,
déduplication, lookups, clés de substitution, calculs de mesures) doit être
**visible sur le canvas** sous forme de transforms, pas cachée dans un
`INSERT ... SELECT`.

`ExecSql` reste autorisé uniquement pour le **plumbing** : créer un schéma/table,
`TRUNCATE`, initialiser ou mettre à jour `control.*`. Les scripts SQL de `sql/`
servent d'**oracle de validation** et de **chemin de secours CLI**, pas de pipeline.

## Pour aller plus loin (rationale données — non répété ici)

- `CONTEXT.md` — glossaire (ETL, `staging`, `warehouse`, transform natif, oracle SQL).
- `docs/architecture_lab1.md` — rôle des couches, rôle de SQL, exclusions du lab.
- `docs/star_schema_design.md` — modèle en étoile, grain, clés de substitution.
- `docs/incremental_load_pattern.md` — pattern watermark et pièges.

## Guides d'application (le « comment » par pipeline)

- `hop/README_pipeline_apache_hop.md` — premier flux pas à pas (Partie A).
- `hop/blueprints/p01..p05` — réglages des transforms pipeline par pipeline.
