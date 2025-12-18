import httpx
from .prompts import SYSTEM

OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
MODEL = "phi3:mini"

async def generate(prompt: str) -> str:
    payload = {
        "model": MODEL,
        "prompt": f"{SYSTEM}\n\n{prompt}",
        "stream": False,
    }
    async with httpx.AsyncClient(timeout=httpx.Timeout(600.0)) as client:
        r = await client.post(OLLAMA_URL, json=payload)
        r.raise_for_status()
        data = r.json()
        return (data.get("response") or "").strip()
