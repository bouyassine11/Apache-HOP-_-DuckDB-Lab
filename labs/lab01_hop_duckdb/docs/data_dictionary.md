# Dictionnaire de données — Lab 1

## `customers`

| Colonne | Type SQL | Contrainte | Description | Exemple | Remarque qualité |
|---|---|---|---|---:|---|
| `customer_id` | INTEGER | PK | Identifiant client supposé unique | 1 | Vérifier les doublons |
| `customer_name` | VARCHAR | NOT NULL | Nom du client | Amina Haddad | Obligatoire |
| `email` | VARCHAR | — | Email client | x@example.com | Peut être manquant |
| `city` | VARCHAR | — | Ville | Casablanca | À standardiser |
| `country` | VARCHAR | — | Pays | MA | Code pays |
| `signup_date` | DATE | — | Date d'inscription | 2024-01-12 | Date valide attendue |
| `segment` | VARCHAR | — | Segment client | Retail | Valeurs attendues : Retail, SMB, Enterprise |

## `categories`

| Colonne | Type SQL | Contrainte | Description |
|---|---|---|---|
| `category_id` | INTEGER | PK | Identifiant catégorie |
| `category_name` | VARCHAR | NOT NULL | Nom de catégorie |
| `department` | VARCHAR | — | Département métier |

## `products`

| Colonne | Type SQL | Contrainte | Description | Remarque qualité |
|---|---|---|---|---|
| `product_id` | INTEGER | PK | Identifiant produit supposé unique | Vérifier les doublons |
| `product_name` | VARCHAR | NOT NULL | Nom produit | Obligatoire |
| `category_id` | INTEGER | FK → categories | Clé vers `categories` | Vérifier la relation |
| `unit_price` | DECIMAL | — | Prix de vente standard | Doit être positif pour les produits actifs |
| `cost_price` | DECIMAL | — | Coût estimé | Doit être positif |
| `active_flag` | INTEGER | — | Produit actif ou non | 1 actif, 0 inactif |

## `orders`

| Colonne | Type SQL | Contrainte | Description | Remarque qualité |
|---|---|---|---|---|
| `order_id` | INTEGER | PK | Identifiant commande | Unique attendu |
| `customer_id` | INTEGER | FK → customers | Client associé | Vérifier la relation vers `customers` |
| `order_date` | DATE | NOT NULL | Date commande | Utilisée pour analyse temporelle |
| `channel` | VARCHAR | — | Canal | Online, Store, Partner |
| `order_status` | VARCHAR | — | Statut commande | Completed, Returned, Cancelled, Shipped |
| `city` | VARCHAR | — | Ville de commande | Peut différer de la ville client |

## `order_items`

| Colonne | Type SQL | Contrainte | Description | Remarque qualité |
|---|---|---|---|---|
| `order_item_id` | INTEGER | PK | Identifiant ligne | Unique attendu |
| `order_id` | INTEGER | FK → orders | Commande associée | Vérifier relation |
| `product_id` | INTEGER | FK → products | Produit vendu | Vérifier relation |
| `quantity` | INTEGER | — | Quantité | Doit être strictement positive |
| `unit_price` | DECIMAL | — | Prix de vente de la ligne | Peut différer du prix catalogue |
| `discount_amount` | DECIMAL | — | Remise de ligne | Doit être >= 0 |

## `payments`

| Colonne | Type SQL | Contrainte | Description | Remarque qualité |
|---|---|---|---|---|
| `payment_id` | INTEGER | PK | Identifiant paiement | Unique attendu |
| `order_id` | INTEGER | FK → orders | Commande associée | Vérifier relation |
| `payment_date` | DATE | — | Date paiement | Peut être après la commande |
| `payment_method` | VARCHAR | — | Moyen de paiement | Card, Cash, Transfer |
| `payment_status` | VARCHAR | — | Statut paiement | Paid, Pending, Refunded, Cancelled |
| `amount` | DECIMAL | — | Montant payé | Attention aux remboursements et montants négatifs |

## `stock_movements`

| Colonne | Type SQL | Contrainte | Description | Remarque qualité |
|---|---|---|---|---|
| `movement_id` | INTEGER | PK | Identifiant mouvement | Unique attendu |
| `product_id` | INTEGER | FK → products | Produit concerné | Vérifier relation |
| `movement_date` | DATE | NOT NULL | Date du mouvement | Obligatoire |
| `movement_type` | VARCHAR | — | Type de mouvement | IN ou OUT |
| `quantity` | INTEGER | — | Quantité mouvement | Doit être positive |
| `warehouse` | VARCHAR | — | Entrepôt | Code local |
