#!/usr/bin/env bash
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

write_fake_dispatcher "$workdir/project/.dx/.devcontainer/src/dx/runtime"
write_fake_dispatcher "$workdir/explicit"

dogfood_home="$workdir/project/.dx/.devcontainer/src/dx/runtime"
output="$(cd "$workdir/project" && env -u DX_HOME dx-mcp github)"
[[ "$output" == "$dogfood_home" ]] || fail "dogfood runtime was not selected (got: $output)"

explicit_home="$workdir/explicit"
output="$(cd "$workdir/project" && DX_HOME="$explicit_home" dx-mcp github)"
[[ "$output" == "$explicit_home" ]] || fail "explicit DX_HOME was not honored (got: $output)"

echo "dx-mcp runtime resolution: dogfood and explicit override pass"