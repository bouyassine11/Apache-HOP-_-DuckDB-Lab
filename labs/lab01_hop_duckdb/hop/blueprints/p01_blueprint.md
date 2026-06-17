# Blueprint - p01_csv_to_staging

> Concepts Hop (projet, pipeline vs workflow, transform, Run) : `../../docs/apache_hop_concepts.md`.

## Objectif

Construire un pipeline Apache Hop qui charge les CSV sources vers `staging.*`. Cette couche est une landing zone typee : elle convertit les types, aligne les schemas et isole les rejets techniques. Elle ne normalise pas les villes, ne filtre pas les statuts metier et ne supprime pas les references orphelines.

## Flow de la sous-pipeline CUSTOMERS

```text
[Read customers.csv]
        |
        v
[Validate customer_id]
        |TRUE
        v
[Select customer fields]
        |
        v
[Write staging.customers]

FALSE -> [Rejects customers]
```

## Transforms utilises

| Transform | Type | Role |
|-----------|------|------|
| Read customers.csv | CSVInput | Lire le fichier CSV avec les champs types |
| Validate customer_id | FilterRows | Rejeter les lignes techniquement inexploitables |
| Select customer fields | SelectValues | Aligner les noms, types et ordre des colonnes |
| Write staging.customers | TableOutput | Ecrire dans DuckDB, truncate avant chargement initial |
| Rejects customers | TextFileOutput | Journaliser les lignes rejetees |

## Definition des champs - CSVInput customers.csv

| Nom du champ | Type | Format | Trim |
|--------------|------|--------|------|
| customer_id | Integer | | none |
| customer_name | String | | none |
| email | String | | none |
| city | String | | both |
| country | String | | none |
| signup_date | Date | yyyy-MM-dd | none |
| segment | String | | none |

## Regles staging

Autorise :

- conversion de types ;
- validation de colonnes obligatoires ;
- rejets techniques ;
- deduplication seulement si necessaire pour eviter un echec de chargement.

Interdit dans `p01` :

- normalisation des villes ;
- enrichissement produit avec categories ;
- filtrage de statuts de commande ;
- suppression des orphelins ;
- calcul de KPI ou de mesures.

## Tables a charger

- `staging.customers`
- `staging.categories`
- `staging.products`
- `staging.orders`
- `staging.order_items`
- `staging.payments`
- `staging.stock_movements`
- `staging.budget` (source de la Partie B : `sales_budget.csv`)

## Reglages cles par transform (dialogue GUI)

Valeurs telles que definies dans `p01_csv_to_staging.hpl` (flux customers) :

| Transform | Reglages a verifier dans le dialogue |
|-----------|--------------------------------------|
| CSVInput | Filename `${DATA_DIR}/customers.csv` ; Separator `,` ; Enclosure `"` ; Header `Y` ; champs types (Date au format `yyyy-MM-dd`, `city` Trim `both`) |
| FilterRows | Condition `customer_id IS NOT NULL` ; Send true to `Select customer fields` ; Send false to `Rejects customers` |
| SelectValues | Remplace le `Dummy` du squelette ; fige noms / types / ordre des colonnes ; **ne pas** normaliser `city` ici |
| TableOutput | Connection `DuckDB_Lab1` ; Schema `staging` ; Table `customers` ; Truncate table `Y` |
| TextFileOutput | Fichier `data/processed/rejects_customers.csv` (journal des rejets) |

## Pieges courants

- Project Home mal defini : `${DATA_DIR}` et la connexion ne se resolvent pas (erreur n1).
- Les `Dummy` du squelette doivent etre remplaces par le vrai transform (ex. `Select Values`).
- Oublier Truncate `Y` : les lignes s'accumulent a chaque Run.
- Apres edition en GUI, re-sauvegarder pour que le XML reste valide.

## Notes importantes

- Le squelette `p01_csv_to_staging.hpl` ne montre que le flux customers. Ouvrez-le dans Hop GUI et ajoutez les autres flux.
- Les scripts SQL servent d'oracle de validation et de secours CLI. Le chemin principal du lab est Hop natif.
- Apres modification dans Hop GUI, re-sauvegardez le fichier pour que le XML soit valide.
