#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
wrapper="${DX_MCP_WRAPPER:-$repo_root/.devcontainer/src/dx/dx-mcp}"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

for tools_home in "$workdir/project/.devcontainer/.dx/.devcontainer/src/dx/runtime" "$workdir/legacy" "$workdir/new tools"; do
  mkdir -p "$tools_home/bin"
  printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "${DX_TOOLS_HOME:-$DX_HOME}" "$@"' > "$tools_home/bin/dx-mcp"
  chmod +x "$tools_home/bin/dx-mcp"
done

cd "$workdir/project"
dogfood_home="$PWD/.devcontainer/.dx/.devcontainer/src/dx/runtime"
output="$(env -u DX_HOME -u DX_TOOLS_HOME bash "$wrapper" github --help)"
[[ "$output" == "$dogfood_home"$'\ngithub\n--help' ]]
output="$(env -u DX_TOOLS_HOME DX_HOME="$workdir/legacy" bash "$wrapper" github)"
[[ "$output" == "$workdir/legacy"$'\ngithub' ]]
if [[ "${DX_MCP_LEGACY:-false}" != true ]]; then
  output="$(DX_HOME="$workdir/legacy" DX_TOOLS_HOME="$workdir/new tools" bash "$wrapper" github)"
  [[ "$output" == "$workdir/new tools"$'\ngithub' ]]
  if DX_TOOLS_HOME="$workdir/missing" bash "$wrapper" github >/dev/null 2>&1; then
    printf 'Invalid explicit tools home unexpectedly succeeded\n' >&2
    exit 1
  fi
fi
if env -u DX_TOOLS_HOME DX_HOME="$workdir/missing" bash "$wrapper" github >/dev/null 2>&1; then
  printf 'Invalid explicit legacy home unexpectedly succeeded\n' >&2
  exit 1
fi
if [[ "${DX_MCP_LEGACY:-false}" == true ]]; then
  printf 'MCP wrapper: legacy, dogfood, arguments and invalid paths pass\n'
else
  printf 'MCP wrapper: tools priority, legacy, dogfood, arguments and invalid paths pass\n'
fi