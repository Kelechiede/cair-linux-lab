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
