#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$ROOT_DIR/.tools/ollama"
mkdir -p "$ROOT_DIR/.tools/mcp-server-github"
mkdir -p "$ROOT_DIR/.tools/mcp-server-github/bin"
mkdir -p "$ROOT_DIR/.bin"

bash "$ROOT_DIR/.tools/ollama/install.sh"
bash "$ROOT_DIR/.tools/mcp-server-github/install.sh"

echo "dx tools ready"
