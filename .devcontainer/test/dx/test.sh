#!/bin/bash
# Dev Container Feature test, run via `devcontainer features test` (task feature:test).
# See https://containers.dev/implementors/features/#testing
set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "Feature does not inject DX_HOME" bash -c "[ -z \"\${DX_HOME:-}\" ]"
check "Go Task baseline is installed" bash -c "task --version | grep -q '^3.53.1$'"
check "jq baseline is installed" bash -c "command -v jq >/dev/null"
check "ripgrep baseline is installed" bash -c "command -v rg >/dev/null"
check "stable runtime installed at /opt/dx" bash -c "test -d /opt/dx"
check "agent instructions present" bash -c "test -f /opt/dx/agents/base.md && test -f /opt/dx/agents/git.md"
check "shared taskfile present" bash -c "test -f /opt/dx/taskfiles/base.yml"
check "dx-mcp launcher is executable" bash -c "test -x /opt/dx/bin/dx-mcp"
check "launcher defaults to /opt/dx" bash -c "grep -Fq 'DX_HOME=\"\${DX_HOME:-/opt/dx}\"' /usr/local/bin/dx-mcp"
check "launcher detects dogfood runtime" bash -c "grep -Fq '\$PWD/.devcontainer/.dx/.devcontainer/src/dx/runtime' /usr/local/bin/dx-mcp"
check "explicit DX_HOME has priority" bash -c "grep -Fq 'if [ -z \"\${DX_HOME:-}\" ]' /usr/local/bin/dx-mcp"
check "dx-mcp reports usage without a server argument" bash -c "dx-mcp 2>&1 | grep -q 'usage: dx-mcp github'"
check "official GitHub MCP image is pinned" bash -c "grep -q 'ghcr.io/github/github-mcp-server:v1.10.1' /opt/dx/bin/dx-mcp"
bash "$(dirname "${BASH_SOURCE[0]}")/test-dx-mcp-resolution.sh"

reportResults
