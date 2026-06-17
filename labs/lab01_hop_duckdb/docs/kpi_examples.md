# Exemples de KPI candidats

## KPI 1 — Chiffre d'affaires brut

- **Définition :** somme de `quantity * unit_price` sur les lignes de commande.
- **Grain :** ligne de commande.
- **Limite :** ne tient pas compte des retours, paiements ou remises si non déduites.

## KPI 2 — Chiffre d'affaires net après remise

- **Définition :** somme de `quantity * unit_price - discount_amount`.
- **Grain :** ligne de commande.
- **Limite :** nécessite une règle sur les commandes annulées, retournées et expédiées.

## KPI 3 — Nombre de commandes complétées

- **Définition :** nombre de commandes avec `order_status = 'Completed'`.
- **Grain :** commande.
- **Limite :** exclut `Shipped` sauf décision métier contraire.

## KPI 4 — Panier moyen

- **Définition :** chiffre d'affaires net / nombre de commandes.
- **Grain :** commande.
- **Limite :** sensible aux retours et aux anomalies de quantité.

## KPI 5 — Taux d'anomalies de qualité

- **Définition :** nombre d'enregistrements problématiques / nombre total d'enregistrements contrôlés.
- **Grain :** contrôle qualité.
- **Limite :** dépend du catalogue de règles qualité retenu.
