#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

cat > "$workdir/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*"
EOF
chmod +x "$workdir/docker"

default_output="$(PATH="$workdir:/usr/bin:/bin" env -u GITHUB_MCP_IMAGE src/dx/runtime/bin/dx-mcp github)"
[[ "$default_output" == *"ghcr.io/github/github-mcp-server:v1.10.1"* ]] || fail "default image is not pinned"

override_output="$(PATH="$workdir:/usr/bin:/bin" GITHUB_MCP_IMAGE="ghcr.io/github/github-mcp-server:test" src/dx/runtime/bin/dx-mcp github)"
[[ "$override_output" == *"ghcr.io/github/github-mcp-server:test"* ]] || fail "GITHUB_MCP_IMAGE override is not honored"

echo "dx-mcp image selection: pinned default and override pass"