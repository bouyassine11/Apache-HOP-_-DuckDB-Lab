-- sql/22_dim_customer.sql
INSERT INTO warehouse.dim_customer
    (customer_key, customer_id_src, customer_name, email, city, country,
     signup_date, segment, loaded_at)
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date, customer_name) AS rn
    FROM staging.customers
    WHERE customer_id IS NOT NULL
      AND customer_name IS NOT NULL
)
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id)       AS customer_key,
    customer_id                                    AS customer_id_src,
    customer_name,
    COALESCE(email, 'unknown@unknown.com')          AS email,
    CASE UPPER(TRIM(city))
        WHEN 'CASABLANCA'  THEN 'Casablanca'
        WHEN 'RABAT'       THEN 'Rabat'
        WHEN 'MARRAKECH'   THEN 'Marrakech'
        WHEN 'FES'         THEN 'Fes'
        WHEN 'FEZ'         THEN 'Fes'
        WHEN 'TANGIER'     THEN 'Tangier'
        WHEN 'TANGER'      THEN 'Tangier'
        WHEN 'AGADIR'      THEN 'Agadir'
        ELSE 'Unknown'
    END                                            AS city,
    country,
    signup_date,
    segment,
    CURRENT_TIMESTAMP                              AS loaded_at
FROM deduped
WHERE rn = 1;
