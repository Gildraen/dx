#!/usr/bin/env bash
set -euo pipefail

source dev-container-features-test-lib

check "Feature exposes the installed runtime" bash -c 'test "$DX_HOME" = /opt/dx'
check "Node baseline is installed" bash -c "command -v node >/dev/null"
check "GitHub CLI baseline is installed" bash -c "command -v gh >/dev/null"
check "GitHub CLI state uses the host devcontainer directory" bash -c 'test "$GH_CONFIG_DIR" = /var/lib/dx/devcontainer/.gh && mountpoint -q /var/lib/dx/devcontainer'
check "GitHub CLI can write configuration without credentials" bash -c '
	set -e
	gh config set editor dx-test-editor
	test "$(gh config get editor)" = dx-test-editor
	test -f "$GH_CONFIG_DIR/config.yml"
'
check "Go Task baseline meets the minimum version" bash -c '
	version="$(task --version)"
	minimum="3.53.1"
	[[ "$(printf "%s\n" "$minimum" "$version" | sort -V | head -n1)" == "$minimum" ]]
'
check "jq baseline is installed" bash -c "command -v jq >/dev/null"
check "ripgrep baseline is installed" bash -c "command -v rg >/dev/null"
check "stable runtime installed at /opt/dx" bash -c "test -d /opt/dx"
check "shared bootstrap present" bash -c "test -f /opt/dx/AGENTS.md"
check "project resources are discovered from .agents" bash -c 'grep -Fq ".agents/agents/*.md" /opt/dx/AGENTS.md && grep -Fq ".agents/skills/*/SKILL.md" /opt/dx/AGENTS.md'
check "shared instructions present" bash -c "test -f /opt/dx/instructions/base.md && test -f /opt/dx/instructions/git.md"
check "shared agents present" bash -c '
	set -e
	shopt -s nullglob
	agents=(/opt/dx/agents/*.md)
	test "${#agents[@]}" -gt 0
	for agent in "${agents[@]}"; do
		test -f "$agent"
	done
'
check "shared skills directory present" bash -c "test -f /opt/dx/skills/README.md"
check "shared skills present" bash -c '
	set -e
	shopt -s nullglob
	dirs=(/opt/dx/skills/*/)
	test "${#dirs[@]}" -gt 0
	for dir in "${dirs[@]}"; do
		test -f "${dir}SKILL.md"
	done
'
check "shared taskfile present" bash -c "test -f /opt/dx/taskfiles/base.yml"
check "runtime contains only the command launcher" bash -c 'test "$(find /opt/dx/bin -maxdepth 1 -type f | wc -l)" -eq 1 && test -f /opt/dx/bin/dx-mcp'
check "dx-mcp launcher is executable" bash -c "test -x /opt/dx/bin/dx-mcp"
check "launcher defaults to /opt/dx" bash -c "grep -Fq 'DX_HOME=\"\${DX_HOME:-/opt/dx}\"' /usr/local/bin/dx-mcp"
check "launcher detects dogfood runtime" bash -c "grep -Fq '\$PWD/.devcontainer/.dx/.devcontainer/src/dx/runtime' /usr/local/bin/dx-mcp"
check "explicit DX_HOME has priority" bash -c "grep -Fq 'if [ -z \"\${DX_HOME:-}\" ]' /usr/local/bin/dx-mcp"
check "dx-mcp reports usage without a server argument" bash -c "dx-mcp 2>&1 | grep -q 'usage: dx-mcp github'"
check "official GitHub MCP image is pinned" bash -c "grep -q 'ghcr.io/github/github-mcp-server:v1.10.1' /opt/dx/bin/dx-mcp"
bash "$(dirname "${BASH_SOURCE[0]}")/test-dx-mcp-resolution.sh"

reportResults