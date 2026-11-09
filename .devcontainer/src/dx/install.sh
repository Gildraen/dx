#!/usr/bin/env bash
# Dev Container Feature install script.
set -euo pipefail

DX_HOME="/opt/dx"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents_ref="${AGENTSREF:-v0.1.0-rc.1}"
tools_ref="${TOOLSREF:-v0.1.0-rc.1}"
download_root="$(mktemp -d)"
trap 'rm -rf "$download_root"' EXIT

install_component() {
	local name="$1" ref="$2"
	local checkout="$download_root/$name"
	git init -q "$checkout"
	git -C "$checkout" remote add origin "https://github.com/Gildraen/dx-$name.git"
	GIT_TERMINAL_PROMPT=0 git -C "$checkout" fetch --depth=1 origin "$ref"
	git -C "$checkout" checkout -q --detach FETCH_HEAD
	rm -rf "$checkout/.git"
	rm -rf "$DX_HOME/components/$name"
	mkdir -p "$DX_HOME/components/$name"
	cp -R "$checkout/." "$DX_HOME/components/$name/"
}

install_component agents "$agents_ref"
install_component tools "$tools_ref"
test -f "$DX_HOME/components/agents/AGENTS.md"
test -x "$DX_HOME/components/tools/bin/dx-mcp"

for resource in AGENTS.md instructions agents skills; do
	rm -rf "$DX_HOME/$resource"
	ln -s "components/agents/$resource" "$DX_HOME/$resource"
done
for resource in bin taskfiles; do
	rm -rf "$DX_HOME/$resource"
	ln -s "components/tools/$resource" "$DX_HOME/$resource"
done
install -m 0755 "$FEATURE_DIR/dx-mcp" /usr/local/bin/dx-mcp

echo "dx components installed at $DX_HOME/components"
