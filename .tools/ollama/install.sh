#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=github-releases depName=ollama/ollama versioning=semver
OLLAMA_VERSION="v0.12.1"

if command -v ollama >/dev/null 2>&1; then
  echo "ollama already available"
  exit 0
fi

echo "ollama not found (expected version $OLLAMA_VERSION)."
echo "Skipping auto-install in dx baseline repo."
echo "Install manually in service repos that require runtime inference."
