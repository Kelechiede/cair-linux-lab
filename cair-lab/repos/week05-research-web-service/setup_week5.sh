#!/bin/bash
set -euo pipefail

BASE="/workspaces/cair-linux-lab/cair-lab/repos/week05-research-web-service"

echo "[1/6] Create folders..."
mkdir -p "$BASE"/{app,nginx,scripts,docs}
mkdir -p "$BASE/nginx/runtime"

echo "[2/6] Write Flask app..."
cat > "$BASE/app/app.py" <<'PY'
from flask import Flask, jsonify
import os
import psycopg2

app = Flask(__name__)

DB_URL = os.getenv("DATABASE_URL", "postgresql://cairuser@localhost:5432/cair_lab")

def q(sql: str):
    with psycopg2.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchall()

@app.get("/health")
def health():
    return jsonify(status="ok")

@app.get("/profiling/summary")
def profiling_summary():
    rows = q("""
        SELECT
          COUNT(*) AS row_count,
          SUM(CASE WHEN full_name IS NULL THEN 1 ELSE 0 END) AS null_full_name,
          SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS null_email,
          SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_age,
          SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city
        FROM profiling.sample_people;
    """)
    (row_count, null_full_name, null_email, null_age, null_city) = rows[0]
    return jsonify(
        table="profiling.sample_people",
        row_count=row_count,
        nulls={
            "full_name": null_full_name,
            "email": null_email,
            "age": null_age,
            "city": null_city
        }
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PY

echo "[3/6] Write nginx server config..."
cat > "$BASE/nginx/research_service.conf" <<'CONF'
server {
    listen 8080;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
CONF

echo "[4/6] Write full nginx.conf..."
cat > "$BASE/nginx/nginx.conf" <<'CONF'
worker_processes 1;

events {
  worker_connections 1024;
}

http {
  access_log off;
  error_log stderr;

  include /workspaces/cair-linux-lab/cair-lab/repos/week05-research-web-service/nginx/research_service.conf;
}
CONF

echo "[5/6] Write run script..."
cat > "$BASE/scripts/run_dev.sh" <<'RUN'
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
RUN

chmod +x "$BASE/scripts/run_dev.sh"

echo "[6/6] Done. Week 5 setup complete."
