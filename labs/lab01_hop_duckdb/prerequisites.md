# Prérequis — Lab 1

## Compétences nécessaires

- SQL de base : `SELECT`, `WHERE`, `JOIN`, `GROUP BY`, agrégations.
- Compréhension minimale des fichiers CSV.
- Différence conceptuelle entre système opérationnel et système analytique.
- Utilisation basique d'un terminal.

## Logiciels à installer

| Logiciel | Rôle | Lien de téléchargement |
|---|---|---|
| Apache Hop | Ingestion visuelle (chemin officiel d'ingestion, pipeline GUI) | https://hop.apache.org/download/ |
| DuckDB CLI | Moteur d'exploration local (requêtes `.read`) | https://duckdb.org/docs/installation/ |
| Driver DuckDB JDBC | Connexion DuckDB depuis Hop (Partie B) | https://duckdb.org/docs/stable/clients/java |
| Git | Récupérer et mettre à jour le matériel | https://git-scm.com/downloads |
| Éditeur de texte | VS Code, IntelliJ, Cursor, Sublime Text… | https://code.visualstudio.com/ |

### 1. Apache Hop

Apache Hop est le **chemin officiel d'ingestion** du lab : le pipeline GUI lit les CSV et charge
les tables `staging.*` dans DuckDB.

Installer Apache Hop Desktop (**version 2.x récente recommandée**, requiert **Java 17 minimum**,
**Java 21 recommandé** pour les dernières versions) depuis https://hop.apache.org/download/

Puis vérifier :

- ouverture de Hop GUI ;
- création d'un projet ;
- lecture d'un fichier CSV ;
- configuration d'une connexion DuckDB/JDBC si disponible dans votre environnement.

Pour la Partie B avec Hop, télécharger le driver `duckdb-jdbc-*.jar` depuis
https://duckdb.org/docs/stable/clients/java, le copier dans le dossier `lib/` du projet Hop,
puis tester la connexion `DuckDB_Lab1`.

### 2. DuckDB CLI

DuckDB est le **moteur d'exploration** du lab : une fois les tables `staging.*` chargées par Hop,
les analyses se font avec la CLI DuckDB.

```bash
duckdb --version
```

Si cette commande ne fonctionne pas, installer DuckDB CLI avant le lab depuis
https://duckdb.org/docs/installation/. Les commandes `.read` utilisées dans les consignes
sont des commandes de la CLI DuckDB. La CLI sert aussi de chemin de secours pour charger
`staging.*` si Apache Hop est indisponible (voir le README).

### 3. Git

Vérifier Git :

```bash
git --version
```

Si la commande est absente, installer Git depuis https://git-scm.com/downloads.

### 4. Éditeur de texte

VS Code (https://code.visualstudio.com/), IntelliJ, Cursor, Sublime Text ou équivalent.

## Préparation avant le lab

1. Décompresser le dossier du lab.
2. Ouvrir `data/raw/` et repérer les fichiers principaux, les fichiers `_april` et le fichier budget.
3. Lire `docs/data_dictionary.md`.
4. Lire `docs/business_questions.md`.
5. Préparer un dossier local de travail (aucun rendu n'est demandé : le lab se fait en séance).

## Note pédagogique

dbt n'est pas utilisé dans ce lab. Il sera introduit au Lab 2, après les séances sur la
modélisation dimensionnelle.

