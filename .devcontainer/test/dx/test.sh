#!/bin/bash
# Dev Container Feature test, run via `devcontainer features test` (task feature:test).
# See https://containers.dev/implementors/features/#testing
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "DX_HOME is set" bash -c "[ \"\$DX_HOME\" = /opt/dx ]"
check "runtime installed at DX_HOME" bash -c "test -d /opt/dx"
check "agent instructions present" bash -c "test -f /opt/dx/agents/base.md && test -f /opt/dx/agents/git.md"
check "shared taskfile present" bash -c "test -f /opt/dx/taskfiles/base.yml"
check "dx-mcp launcher is executable" bash -c "test -x /opt/dx/bin/dx-mcp"
check "global dx-mcp launcher resolves DX_HOME" bash -c "grep -q 'DX_HOME' /usr/local/bin/dx-mcp"
check "dx-mcp reports usage without a server argument" bash -c "dx-mcp 2>&1 | grep -q 'usage: dx-mcp github'"
check "official GitHub MCP image is pinned" bash -c "grep -q 'ghcr.io/github/github-mcp-server:v1.10.1' /opt/dx/bin/dx-mcp"
bash "$(dirname "${BASH_SOURCE[0]}")/test-dx-mcp-resolution.sh"

reportResults
