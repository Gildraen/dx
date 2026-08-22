#!/usr/bin/env bash
# Validates that every *.json / *.jsonc file in the repo parses correctly.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

status=0
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  if ! node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$file"; then
    echo "invalid JSON: $file" >&2
    status=1
  fi
done < <(git ls-files -z --cached --others --exclude-standard '*.json' '*.jsonc')

if [[ $status -eq 0 ]]; then
  echo "all JSON/JSONC files parse correctly"
fi
exit $status
