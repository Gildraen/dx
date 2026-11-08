#!/usr/bin/env bash
set -euo pipefail

source dev-container-features-test-lib

check "Feature exposes the installed runtime" bash -c 'test "$DX_HOME" = /opt/dx'
check "Feature exposes installed agents" bash -c 'test "$DX_AGENTS_HOME" = /opt/dx/components/agents'
check "Feature exposes installed tools" bash -c 'test "$DX_TOOLS_HOME" = /opt/dx/components/tools'
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
check "agents component snapshot is installed" bash -c '
	set -e
	test -f "$DX_AGENTS_HOME/AGENTS.md"
	for resource in instructions agents skills; do
		test -d "$DX_AGENTS_HOME/$resource"
	done
	test ! -e "$DX_AGENTS_HOME/.git"
'
check "tools component snapshot is installed" bash -c '
	set -e
	test -x "$DX_TOOLS_HOME/bin/dx-mcp"
	test -f "$DX_TOOLS_HOME/taskfiles/base.yml"
	test ! -e "$DX_TOOLS_HOME/.git"
'
check "six legacy paths link to the installed components" bash -c '
	set -e
	for resource in AGENTS.md instructions agents skills bin taskfiles; do
		component=agents
		[[ "$resource" != bin && "$resource" != taskfiles ]] || component=tools
		test -L "/opt/dx/$resource"
		test "$(readlink "/opt/dx/$resource")" = "components/$component/$resource"
		test -e "/opt/dx/$resource"
	done
'
check "DX wrapper is installed and executable" bash -c 'test -x /usr/local/bin/dx-mcp && test "$(command -v dx-mcp)" = /usr/local/bin/dx-mcp'
check "installed wrapper resolves component homes" env DX_MCP_WRAPPER=/usr/local/bin/dx-mcp bash "$(dirname "${BASH_SOURCE[0]}")/test-dx-mcp-resolution.sh"

reportResults