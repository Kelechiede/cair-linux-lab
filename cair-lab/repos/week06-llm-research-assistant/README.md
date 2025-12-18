# Week 6 — Local LLM Research Assistant (FastAPI + Ollama + PostgreSQL) (CAIR-aligned)

## What this demonstrates
- Local open-source LLM via Ollama (no cloud APIs)
- FastAPI research-support service
- PostgreSQL integration (profiling data from Week 3)
- Strong SQL safety controls (read-only enforcement)
- Prompt & response audit logging for governance

## Architecture
- FastAPI backend (port 9000)
- Ollama local LLM runtime
- PostgreSQL as research datastore
- Full audit trail in `logs/prompts.log`

## Run
```bash
bash scripts/run_dev.sh
