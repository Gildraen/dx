#!/usr/bin/env bash
# Ensures the repository includes the required contract files and executable bits.
# Assumes it is run from the repo root (as Task does).
set -euo pipefail

required_files=(
  ".gitmodules"
  ".devcontainer/src/dx/install.sh"
  ".devcontainer/src/dx/dx-mcp"
  ".devcontainer/components/agents/AGENTS.md"
  ".devcontainer/components/tools/taskfiles/base.yml"
  ".devcontainer/test/dx/test-resource-discovery.sh"
  ".devcontainer/test/dx/test-install.sh"
  ".devcontainer/test/dx/test-dx-mcp-resolution.sh"
  ".devcontainer/src/dx/devcontainer-feature.json"
  ".devcontainer/devcontainer.json"
  ".github/workflows/validate.yml"
  ".github/workflows/maintenance.yml"
  ".github/workflows/reusable-validate.yml"
  ".github/workflows/reusable-devcontainer-test.yml"
  ".github/workflows/reusable-feature-test.yml"
  ".github/workflows/reusable-maintenance.yml"
  ".github/workflows/release.yml"
)

required_tracked_executable=(
  ".devcontainer/src/dx/install.sh"
)

status=0

# These files must exist; the repo contract is broken otherwise.
for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "required file is missing: $file" >&2
    status=1
    continue
  fi
done

# These entry points must also be committed and executable, since the Feature/CI run them directly.
for file in "${required_tracked_executable[@]}"; do
  if ! git ls-files --error-unmatch -- "$file" >/dev/null 2>&1; then
    echo "required file is not tracked: $file" >&2
    status=1
    continue
  fi

  entry=$(git ls-files --stage -- "$file")
  mode=${entry%% *}
  if [[ "$mode" != "100755" ]]; then
    echo "not executable in git: $file" >&2
    status=1
  fi
done

exit "$status"
