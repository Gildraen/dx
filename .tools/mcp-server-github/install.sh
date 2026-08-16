#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN_DIR="$ROOT_DIR/.tools/mcp-server-github/bin"
LAUNCHER="$BIN_DIR/github-mcp-server"

# renovate: datasource=npm depName=@modelcontextprotocol/server-github versioning=npm
GITHUB_MCP_SERVER_VERSION="2026.8.4"

mkdir -p "$BIN_DIR"

cat > "$LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

exec npx -y @modelcontextprotocol/server-github@2026.8.4 "$@"
EOF

chmod +x "$LAUNCHER"
echo "github MCP launcher ready: $LAUNCHER"
