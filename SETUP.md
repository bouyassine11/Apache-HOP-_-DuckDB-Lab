# Guide d'installation

Ce guide prépare votre machine pour les labs BI. Il couvre uniquement la configuration
**commune à tous les labs**. Chaque lab installe ensuite les outils qui lui sont propres
(DuckDB, Apache Hop, dbt, ClickHouse…) via son fichier `prerequisites.md`.

## 1. Installer Git

Vérifier Git :

```bash
git --version
```

Si la commande est absente, installer Git depuis :

```text
https://git-scm.com/downloads
```

## 2. Récupérer le dépôt

Cloner le dépôt une fois :

```bash
git clone https://github.com/lnajdi/business-intelligence-labs.git
cd business-intelligence-labs
```

Avant chaque séance de lab, mettre à jour votre copie locale :

```bash
git pull
```

## 3. Installer un éditeur

Utiliser VS Code, IntelliJ, Cursor, Sublime Text ou un autre éditeur de texte.

## 4. Outils spécifiques à chaque lab

Les labs sont publiés progressivement et reposent sur des outils différents. Les logiciels à
installer, leur vérification et un test d'installation sont décrits dans le `prerequisites.md`
du lab concerné, par exemple :

- Lab 1 → `labs/lab01_hop_duckdb/prerequisites.md` (DuckDB CLI, Apache Hop, driver JDBC).

Avant chaque séance, ouvrir le `prerequisites.md` du lab du jour et installer les outils
indiqués.

## Notes

- Les labs se font en séance ; aucun rendu n'est à committer dans le dépôt.
- Ne pas committer les bases générées localement (par ex. `*.duckdb`), captures d'écran ou
  travaux personnels.
