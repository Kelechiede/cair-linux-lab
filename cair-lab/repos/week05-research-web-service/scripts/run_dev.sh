#!/bin/bash
set -euo pipefail

BASE="/workspaces/cair-linux-lab/cair-lab/repos/week05-research-web-service"
NGINX_PREFIX="$BASE/nginx/runtime"
NGINX_CONF="$BASE/nginx/nginx.conf"

export DATABASE_URL="${DATABASE_URL:-postgresql://cairuser@localhost:5432/cair_lab}"

sudo nginx -s stop 2>/dev/null || true
pkill -f "$BASE/app/app.py" 2>/dev/null || true
sudo service postgresql start >/dev/null

python3 "$BASE/app/app.py" &
FLASK_PID=$!

mkdir -p "$NGINX_PREFIX"
sudo nginx -p "$NGINX_PREFIX" -c "$NGINX_CONF"

echo "Service ready on http://localhost:8080"
wait $FLASK_PID
