#!/bin/bash
set -euo pipefail

CONN="postgresql://cairuser@localhost:5432/cair_lab"
BASE="/workspaces/cair-linux-lab/cair-lab/repos/week03-profile-analytics"
OUT="$BASE/reports/profile_report.md"

mkdir -p "$BASE/reports"

{
  echo "# Profile Analytics Report"
  echo ""
  echo "**Generated (UTC):** $(date -u)"
  echo ""
  echo "## Dataset"
  echo "\`profiling.sample_people\`"
  echo ""
  echo "## Summary Metrics"
  echo '```'
  psql "$CONN" -f "$BASE/sql/02_profiling_queries.sql"
  echo '```'
  echo ""
  echo "## Performance Evidence (EXPLAIN ANALYZE)"
  echo '```'
  psql "$CONN" -f "$BASE/sql/03_explain_analyze.sql"
  echo '```'
} > "$OUT"

echo "Report written to: $OUT"
