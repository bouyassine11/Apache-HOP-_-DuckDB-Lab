# Données sources — Lab 1

Les fichiers CSV dans `data/raw/` représentent des exports opérationnels et des extensions
pour la partie B.

## Sources principales — partie A

| Fichier | Type | Description |
|---|---|---|
| `customers.csv` | Référence | Clients et segments |
| `categories.csv` | Référence | Catégories produit |
| `products.csv` | Référence | Produits, prix et coût |
| `orders.csv` | Transaction | Commandes client |
| `order_items.csv` | Transaction détaillée | Lignes de commande |
| `payments.csv` | Transaction | Paiements associés aux commandes |
| `stock_movements.csv` | Transaction logistique | Entrées et sorties de stock |

## Extensions — partie B

| Fichier | Usage |
|---|---|
| `orders_april.csv` | Batch incrémental d'avril 2025 |
| `order_items_april.csv` | Lignes du batch incrémental |
| `payments_april.csv` | Paiements du batch incrémental |
| `sales_budget.csv` | Objectifs budgétaires pour budget vs réalisé |

## Dossier `data/processed/`

Ce dossier est réservé aux exports Apache Hop optionnels, par exemple `rejects_<table>.csv`
pour les lignes rejetées. Il n'est pas nécessaire pour exécuter les scripts SQL de référence.

## Important

Le jeu de données contient volontairement des problèmes de qualité : doublons, clés absentes,
valeurs nulles, prix suspects, quantités négatives et relations cassées. Ces anomalies
alimentent l'exploration BI.
