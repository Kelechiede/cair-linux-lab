#!/bin/bash
set -euo pipefail

echo "[0/3] Ensure PostgreSQL running..."
sudo service postgresql start >/dev/null

BASE="/workspaces/cair-linux-lab/cair-lab/repos/week06-llm-research-assistant"
export DATABASE_URL="${DATABASE_URL:-postgresql://cairuser@localhost:5432/cair_lab}"

echo "[1/3] Ensure Ollama..."
bash "$BASE/scripts/setup_ollama.sh"

echo "[2/3] Start FastAPI on port 9000..."
python3 -m uvicorn app.main:app \
  --host 0.0.0.0 \
  --port 9000 \
  --app-dir "$BASE"
