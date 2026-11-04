#!/usr/bin/env bash
# Runs the Dev Container Feature test suite against the local Docker daemon.
# Assumes it is run from the repo root (as Task does).
set -euo pipefail

mkdir -p .tmp
TMPDIR="$PWD/.tmp" npx --yes @devcontainers/cli@0.88.0 features test --features dx --project-folder .devcontainer --base-image mcr.microsoft.com/devcontainers/base:ubuntu-24.04 --remote-user vscode --skip-scenarios --skip-duplicated
