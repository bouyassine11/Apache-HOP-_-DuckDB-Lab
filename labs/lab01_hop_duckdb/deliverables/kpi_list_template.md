# Liste initiale de KPI — Lab 1

> **Guide des colonnes**
> - **Définition** : formule ou règle de calcul précise (ex. SUM(unit_price * quantity))
> - **Grain** : niveau de détail le plus fin (ex. ligne de commande, commande, mois × canal)
> - **Source** : table(s) DuckDB utilisée(s)
> - **Filtres** : conditions obligatoires (ex. order_status = 'Completed')
> - **Limites** : réserves ou biais connus (ex. exclut les remboursements partiels)
> - **Décision associée** : question métier que ce KPI aide à trancher

| KPI | Définition | Grain | Source | Filtres | Limites | Décision associée |
|---|---|---|---|---|---|---|
| *Exemple — CA net* | *SUM(unit_price × quantity − discount_amount)* | *Ligne de commande* | *staging.order_items, staging.orders* | *order_status = 'Completed'* | *Exclut les retours partiels non enregistrés* | *Quel canal génère le plus de revenu ce mois ?* |
| Chiffre d'affaires net |  |  |  |  |  |  |
| Nombre de commandes |  |  |  |  |  |  |
| Panier moyen |  |  |  |  |  |  |
| Taux de retour |  |  |  |  |  |  |
| CA par canal |  |  |  |  |  |  |

## Questions ouvertes

1.
2.
3.
