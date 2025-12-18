#!/bin/bash
set -euo pipefail

BASE="/workspaces/cair-linux-lab/cair-lab/repos/week06-llm-research-assistant"

echo "[1/7] Create folders..."
mkdir -p "$BASE"/{app,scripts,docs,logs}

echo "[2/7] Write prompts..."
cat > "$BASE/app/prompts.py" <<'PY'
SYSTEM = """You are an internal Research IT assistant for a university HPC/data center.
You must be concise, technical, and safety-focused.
If asked to generate SQL, output ONLY safe read-only SQL (SELECT/WITH/EXPLAIN) and nothing destructive.
Never suggest DROP/DELETE/UPDATE/ALTER/INSERT/COPY.
"""

PROFILE_SUMMARY = """Given the profiling summary below, explain:
1) Key issues (nulls/invalids)
2) What it means for researchers
3) Next recommended checks (3 bullets)
Return a short structured response.

Profiling summary JSON:
{summary_json}
"""

SQL_SUGGEST = """You will propose ONE safe read-only SQL query to answer the user's question.
Rules:
- ONLY SELECT/WITH/EXPLAIN allowed
- Must reference schema {schema} and table {table}
- No semicolons inside strings
- Return only SQL, nothing else.

User question: {question}
"""
PY

echo "[3/7] Write safety layer..."
cat > "$BASE/app/safety.py" <<'PY'
import re

DISALLOWED = re.compile(
    r"\b(drop|delete|update|insert|alter|truncate|grant|revoke|copy|create)\b",
    re.IGNORECASE
)

def ensure_read_only_sql(sql: str) -> str:
    s = sql.strip().strip(";").strip()
    if not s:
        raise ValueError("Empty SQL")
    if DISALLOWED.search(s):
        raise ValueError("Unsafe SQL detected (write/destructive keyword).")
    if not re.match(r"^(select|with|explain)\b", s, re.IGNORECASE):
        raise ValueError("Only SELECT/WITH/EXPLAIN statements are allowed.")
    return s + ";"
PY

echo "[4/7] Write LLM client (Ollama via HTTP)..."
cat > "$BASE/app/llm.py" <<'PY'
import httpx
from .prompts import SYSTEM

OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
MODEL = "llama3.1:8b"

async def generate(prompt: str) -> str:
    payload = {
        "model": MODEL,
        "prompt": f"{SYSTEM}\n\n{prompt}",
        "stream": False,
    }
    async with httpx.AsyncClient(timeout=120.0) as client:
        r = await client.post(OLLAMA_URL, json=payload)
        r.raise_for_status()
        data = r.json()
        return (data.get("response") or "").strip()
PY

echo "[5/7] Write FastAPI app..."
cat > "$BASE/app/main.py" <<'PY'
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os, json, datetime
import psycopg2

from .llm import generate
from .prompts import PROFILE_SUMMARY, SQL_SUGGEST
from .safety import ensure_read_only_sql

app = FastAPI(
    title="Week 6 — CAIR LLM Research Assistant (Local + Auditable)"
)

DB_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://cairuser@localhost:5432/cair_lab"
)

LOG_PATH = (
    "/workspaces/cair-linux-lab/"
    "cair-lab/repos/week06-llm-research-assistant/logs/prompts.log"
)

SCHEMA = "profiling"
TABLE = "sample_people"

class AskBody(BaseModel):
    question: str

def log_event(event: dict):
    event["ts"] = datetime.datetime.utcnow().isoformat() + "Z"
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(event) + "\n")

def q(sql: str):
    with psycopg2.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchall()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/profiling/summary")
def profiling_summary():
    rows = q(f"""
        SELECT
          COUNT(*) AS row_count,
          SUM(CASE WHEN full_name IS NULL THEN 1 ELSE 0 END) AS null_full_name,
          SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS null_email,
          SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_age,
          SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city
        FROM {SCHEMA}.{TABLE};
    """)
    (row_count, null_full_name, null_email, null_age, null_city) = rows[0]
    return {
        "table": f"{SCHEMA}.{TABLE}",
        "row_count": row_count,
        "nulls": {
            "full_name": null_full_name,
            "email": null_email,
            "age": null_age,
            "city": null_city
        }
    }

@app.post("/ai/explain_profiling")
async def ai_explain_profiling():
    summary = profiling_summary()
    prompt = PROFILE_SUMMARY.format(
        summary_json=json.dumps(summary, indent=2)
    )
    try:
        answer = await generate(prompt)
        log_event({
            "endpoint": "ai_explain_profiling",
            "prompt": prompt,
            "response": answer
        })
        return {
            "summary": summary,
            "explanation": answer
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ai/sql_suggest")
async def ai_sql_suggest(body: AskBody):
    prompt = SQL_SUGGEST.format(
        schema=SCHEMA,
        table=TABLE,
        question=body.question
    )
    try:
        sql = await generate(prompt)
        sql = ensure_read_only_sql(sql)
        log_event({
            "endpoint": "ai_sql_suggest",
            "question": body.question,
            "sql": sql
        })
        return {
            "question": body.question,
            "sql": sql
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
PY

echo "[6/7] Write runner scripts..."

cat > "$BASE/scripts/setup_ollama.sh" <<'SH'
#!/bin/bash
set -euo pipefail

if ! command -v ollama >/dev/null 2>&1; then
  echo "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

echo "Starting Ollama server..."
nohup ollama serve >/tmp/ollama.log 2>&1 &

echo "Pulling model llama3.1:8b..."
ollama pull llama3.1:8b

echo "Ollama ready."
SH

cat > "$BASE/scripts/run_dev.sh" <<'SH'
#!/bin/bash
set -euo pipefail

BASE="/workspaces/cair-linux-lab/cair-lab/repos/week06-llm-research-assistant"
export DATABASE_URL="${DATABASE_URL:-postgresql://cairuser@localhost:5432/cair_lab}"

echo "[0/3] Ensure PostgreSQL running..."
sudo service postgresql start >/dev/null

echo "[1/3] Ensure Ollama..."
bash "$BASE/scripts/setup_ollama.sh"

echo "[2/3] Start FastAPI on port 9000..."
python3 -m uvicorn app.main:app \
  --host 0.0.0.0 \
  --port 9000 \
  --app-dir "$BASE"
SH

chmod +x "$BASE/scripts/setup_ollama.sh" "$BASE/scripts/run_dev.sh"

echo "[7/7] Write README..."
cat > "$BASE/README.md" <<'MD'
# Week 6 — Local LLM Research Assistant (FastAPI + Ollama + PostgreSQL) (CAIR-aligned)

## What this demonstrates
- Local open-source LLM via Ollama (no cloud APIs)
- FastAPI research-support service
- PostgreSQL integration (profiling data)
- Strong SQL safety controls
- Prompt & response audit logging

## Run
```bash
bash scripts/run_dev.sh
