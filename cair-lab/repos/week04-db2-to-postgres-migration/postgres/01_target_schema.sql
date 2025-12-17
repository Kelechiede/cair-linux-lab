CREATE SCHEMA IF NOT EXISTS migration;

DROP TABLE IF EXISTS migration.orders;
DROP TABLE IF EXISTS migration.customer;

CREATE TABLE migration.customer (
  customer_id INTEGER PRIMARY KEY,
  full_name   TEXT NOT NULL,
  email       TEXT,
  created_at  TIMESTAMP
);

CREATE TABLE migration.orders (
  order_id    INTEGER PRIMARY KEY,
  customer_id INTEGER REFERENCES migration.customer(customer_id),
  amount      NUMERIC(12,2),
  order_ts    TIMESTAMP
);
