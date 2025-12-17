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
