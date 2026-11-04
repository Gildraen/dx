#!/usr/bin/env bash
# Checks that dx-mcp picks the dogfood worktree runtime when present, and honors an explicit DX_HOME override.
set -euo pipefail

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

write_fake_dispatcher() {
  local runtime_dir="$1"
  mkdir -p "$runtime_dir/bin"
  printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$DX_HOME"' > "$runtime_dir/bin/dx-mcp"
  chmod +x "$runtime_dir/bin/dx-mcp"
}

write_fake_dispatcher "$workdir/project/.devcontainer/.dx/.devcontainer/src/dx/runtime"
write_fake_dispatcher "$workdir/explicit"
mkdir -p "$workdir/fake-bin"
cat > "$workdir/fake-bin/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*"
EOF
chmod +x "$workdir/fake-bin/docker"

# No DX_HOME set: must prefer the dogfood worktree runtime over the installed one.
dogfood_home="$workdir/project/.devcontainer/.dx/.devcontainer/src/dx/runtime"
output="$(cd "$workdir/project" && env -u DX_HOME dx-mcp github)"
[[ "$output" == "$dogfood_home" ]] || fail "dogfood runtime was not selected (got: $output)"

# DX_HOME set: must take priority over the dogfood worktree.
explicit_home="$workdir/explicit"
output="$(cd "$workdir/project" && DX_HOME="$explicit_home" dx-mcp github)"
[[ "$output" == "$explicit_home" ]] || fail "explicit DX_HOME was not honored (got: $output)"

# With neither override nor dogfood checkout, dispatch must use the installed runtime.
mkdir -p "$workdir/stable-project"
output="$(cd "$workdir/stable-project" && env -u DX_HOME PATH="$workdir/fake-bin:$PATH" dx-mcp github)"
[[ "$output" == *"ghcr.io/github/github-mcp-server:v1.10.1"* ]] || fail "installed runtime fallback was not selected"

echo "dx-mcp runtime resolution: dogfood, override, and installed fallback pass"