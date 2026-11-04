#!/usr/bin/env bash
# Validates that every *.json file in the repo parses correctly.
# Assumes it is run from the repo root (as Task does).
set -euo pipefail

status=0
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  if ! node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$file"; then
    echo "invalid JSON: $file" >&2
    status=1
  fi
done < <(git ls-files -z --cached --others --exclude-standard '*.json')

if [[ $status -eq 0 ]]; then
  echo "all JSON files parse correctly"
fi
exit $status
