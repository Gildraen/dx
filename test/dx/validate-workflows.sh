#!/usr/bin/env bash
# Validates that every tracked GitHub Actions workflow is syntactically valid YAML.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

status=0
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  if ! npx --yes js-yaml "$file" >/dev/null; then
    echo "invalid YAML: $file" >&2
    status=1
  fi
done < <(git ls-files -z --cached --others --exclude-standard '.github/workflows/*.yml' '.github/workflows/*.yaml')

if [[ $status -eq 0 ]]; then
  echo "all workflow files are valid YAML"
fi
exit $status
