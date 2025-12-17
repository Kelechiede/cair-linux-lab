#!/bin/bash
set -euo pipefail

CONN="postgresql://cairuser@localhost:5432/cair_lab"
BASE="/workspaces/cair-linux-lab/cair-lab/repos/week04-db2-to-postgres-migration"

echo "[1/4] Apply target schema..."
psql "$CONN" -f "$BASE/postgres/01_target_schema.sql"

echo "[2/4] Load CSV exports (simulated Db2 extracts)..."
psql "$CONN" <<SQL
\\copy migration.customer FROM '$BASE/sample_data/customer.csv' CSV HEADER
\\copy migration.orders   FROM '$BASE/sample_data/orders.csv'   CSV HEADER
SQL

echo "[3/4] Run validation checks..."
psql "$CONN" -f "$BASE/validate/01_validate.sql"

echo "[4/4] Done."
echo "Tip: run '\\dt migration.*' to confirm tables."
