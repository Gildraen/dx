#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
taskfile="$repo_root/.devcontainer/src/dx/runtime/taskfiles/base.yml"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

project="$workdir/project"
dogfood_runtime="$project/.devcontainer/.dx/.devcontainer/src/dx/runtime"
mkdir -p "$dogfood_runtime" "$workdir/explicit"

stable_output="$(env -u DX_HOME task --dir "$workdir" --taskfile "$taskfile" doctor)"
[[ "$stable_output" == *"DX_HOME=/opt/dx"* ]] || fail "doctor did not select the stable runtime"
[[ "$stable_output" == *"runtime: found"* ]] || fail "doctor did not find the stable runtime"

dogfood_output="$(task --dir "$project" --taskfile "$taskfile" doctor)"
[[ "$dogfood_output" == *"DX_HOME=$dogfood_runtime"* ]] || fail "doctor did not resolve the documented dogfood path"
[[ "$dogfood_output" == *"runtime: found"* ]] || fail "doctor did not find the dogfood runtime"

explicit_output="$(DX_HOME="$workdir/explicit" task --dir "$project" --taskfile "$taskfile" doctor)"
[[ "$explicit_output" == *"DX_HOME=$workdir/explicit"* ]] || fail "doctor did not honor DX_HOME"

if (DX_HOME="$workdir/missing" task --dir "$project" --taskfile "$taskfile" doctor >/dev/null 2>&1); then
  fail "doctor succeeded for a missing explicit runtime"
fi

echo "dx doctor runtime resolution and missing-runtime failure pass"
