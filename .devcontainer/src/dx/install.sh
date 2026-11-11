#!/usr/bin/env bash
# Dev Container Feature install script.
set -euo pipefail

DX_HOME="/opt/dx"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents_version="${AGENTSVERSION:-v0.1.0-rc.1}"
agents_commit="${AGENTSCOMMIT:-a448037a8b96b2269ac1b46f0ff2018738083c1e}"
tools_version="${TOOLSVERSION:-v0.1.0-rc.1}"
tools_commit="${TOOLSCOMMIT:-6630f37ffdc3a8c51af0f4795145a4743a61584b}"
download_root="$(mktemp -d)"
trap 'rm -rf "$download_root"' EXIT

install_component() {
	local name="$1" version="$2" commit="$3" resolved_commit
	local checkout="$download_root/$name"
	if [[ ! "$commit" =~ ^[0-9a-f]{40}$ ]]; then
		printf 'Invalid commit SHA for %s: %s\n' "$name" "$commit" >&2
		return 1
	fi
	git init -q "$checkout"
	git -C "$checkout" remote add origin "https://github.com/Gildraen/dx-$name.git"
	GIT_TERMINAL_PROMPT=0 git -C "$checkout" fetch --depth=1 origin "$version"
	resolved_commit="$(git -C "$checkout" rev-parse --verify 'FETCH_HEAD^{commit}')"
	if [[ "$resolved_commit" != "$commit" ]]; then
		printf 'Tag %s for %s resolves to %s, which does not match expected commit SHA %s\n' "$version" "$name" "$resolved_commit" "$commit" >&2
		return 1
	fi
	git -C "$checkout" checkout -q --detach "$commit"
	rm -rf "$checkout/.git"
	rm -rf "$DX_HOME/components/$name"
	mkdir -p "$DX_HOME/components/$name"
	cp -R "$checkout/." "$DX_HOME/components/$name/"
}

install_component agents "$agents_version" "$agents_commit"
install_component tools "$tools_version" "$tools_commit"
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
