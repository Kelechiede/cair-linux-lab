-- Week 4 validation checks (Db2 -> Postgres migration simulation)

-- A) Row counts
SELECT 'migration.customer' AS table_name, COUNT(*) AS row_count FROM migration.customer
UNION ALL
SELECT 'migration.orders', COUNT(*) FROM migration.orders;

-- B) Orphan orders (should be 0)
SELECT COUNT(*) AS orphan_orders
FROM migration.orders o
LEFT JOIN migration.customer c
  ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- C) Basic data quality checks
SELECT
  SUM(CASE WHEN full_name IS NULL OR full_name = '' THEN 1 ELSE 0 END) AS missing_full_name,
  SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) AS missing_email
FROM migration.customer;

-- D) Duplicates (should be 0)
SELECT COUNT(*) AS duplicate_customer_ids
FROM (
  SELECT customer_id
  FROM migration.customer
  GROUP BY customer_id
  HAVING COUNT(*) > 1
) d;
