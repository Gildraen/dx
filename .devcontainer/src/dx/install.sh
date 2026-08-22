#!/usr/bin/env bash
# Dev Container Feature install script.
# Copies the versioned DX runtime into DX_HOME.
set -euo pipefail

DX_HOME="/opt/dx"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$DX_HOME"
cp -R "$FEATURE_DIR/runtime/." "$DX_HOME/"
find "$DX_HOME/bin" -maxdepth 1 -type f -exec chmod +x {} \;

install -m 0755 /dev/stdin /usr/local/bin/dx-mcp <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DX_HOME:-}" ] && [ -d "$PWD/.dx/.devcontainer/src/dx/runtime" ]; then
	DX_HOME="$PWD/.dx/.devcontainer/src/dx/runtime"
else
	DX_HOME="${DX_HOME:-/opt/dx}"
fi

exec "$DX_HOME/bin/dx-mcp" "$@"
EOF

echo "dx runtime installed at $DX_HOME"
