#!/bin/bash
set -euo pipefail

if ! command -v ollama >/dev/null 2>&1; then
  echo "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

echo "Starting Ollama server (Codespaces/systemd-safe)..."
pkill -f "ollama serve" >/dev/null 2>&1 || true
nohup ollama serve > /tmp/ollama.log 2>&1 &
sleep 2

echo "Checking Ollama API..."
curl -fsS http://127.0.0.1:11434/api/tags >/dev/null

echo "Pulling model llama3.1:8b..."
ollama pull llama3.1:8b

echo "Ollama ready."
