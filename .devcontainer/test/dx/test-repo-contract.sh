#!/usr/bin/env bash
# Non-Feature dx test suite: devcontainer config, Feature manifest, and doc/workflow pins.
# Assumes it is run from the repo root (as Task does).
set -euo pipefail

# Fast syntax sanity checks, cheap enough to run before the heavier checks below.
test -x .devcontainer/src/dx/runtime/bin/dx-mcp
bash -n .devcontainer/src/dx/runtime/bin/dx-mcp
bash -n .devcontainer/test/dx/test-dx-mcp-resolution.sh
bash -n .devcontainer/test/dx/test-dx-mcp-image.sh
bash -n .devcontainer/test/dx/test-task-doctor.sh
bash -n .devcontainer/test/dx/test-resource-discovery.sh

# Shared skills follow the Agent Skills frontmatter contract.
for skill_dir in .devcontainer/src/dx/runtime/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  test -f "${skill_dir}SKILL.md"
  declared_skill="$(sed -n '/^---$/,/^---$/s/^name: *//p' "${skill_dir}SKILL.md" | head -n1 | tr -d "'\"")"
  [[ "$declared_skill" == "$skill_name" ]]
  rg -q '^description: .+' "${skill_dir}SKILL.md"
done
# Skill reference contract: an agent that names a skill by its exact hyphenated
# name (e.g. `review-quick`) commits to that skill actually existing.
while IFS= read -r skill_name; do
  test -f ".devcontainer/src/dx/runtime/skills/$skill_name/SKILL.md"
done < <(grep -ohP '`\K[a-z][a-z0-9]*(-[a-z0-9]+)+(?=`)' .devcontainer/src/dx/runtime/agents/*.md | sort -u)

# Devcontainer contract: must mount the workspace by path, not bake in a host-specific location.
node <<'EOF'
const devcontainer = require('./.devcontainer/devcontainer.json');
const marker = '${localWorkspaceFolder}';
if (devcontainer.workspaceFolder !== marker) process.exit(1);
if (!devcontainer.workspaceMount.includes(`source=${marker}`) || !devcontainer.workspaceMount.includes(`target=${marker}`)) process.exit(1);
if (devcontainer.remoteEnv.HOST_PROJECT_PATH != null || devcontainer.mounts != null) process.exit(1);
if (devcontainer.remoteEnv.GH_CONFIG_DIR != null) process.exit(1);
EOF

# Feature manifest contract: must depend on the documented tool baseline and never chain after another Feature.
node -e "
const f = require('./.devcontainer/src/dx/devcontainer-feature.json');
const d = f.dependsOn;
const required = [
  'ghcr.io/devcontainers/features/node:2',
  'ghcr.io/devcontainers/features/github-cli:1',
  'ghcr.io/devcontainers-extra/features/go-task:1',
  'ghcr.io/devcontainers-extra/features/apt-get-packages:1',
];
for (const k of required) if (d[k] == null) process.exit(1);
if (f.installsAfter != null) process.exit(1);
"

# CI contract: must trust the Remote Taskfile host, and Renovate must be free to bump Go Task upward.
grep -q 'TASK_REMOTE_TRUSTED_HOSTS: github.com' .github/workflows/reusable-validate.yml

# CI contract: Go Task must stay at or above the minimum version Remote Taskfiles require (currently 3.53.1).
task_version="$(grep -oP 'version:\s*\K[0-9]+\.[0-9]+\.[0-9]+' .github/workflows/reusable-validate.yml)"
[[ "$(printf '%s\n' '3.53.1' "$task_version" | sort -V | head -n1)" == '3.53.1' ]]

# Doc version contract: docs must reference the Feature's actual released version (from the manifest), never a stale or floating tag.
feature_version="$(node -p "require('./.devcontainer/src/dx/devcontainer-feature.json').version")"
rg -qF "ghcr.io/gildraen/dx/dx:${feature_version}" docs/consumer.md
! rg -qP 'reusable-(validate|maintenance)\.yml@v[0-9]+\.[0-9]+\.[0-9]+' README.md docs
! rg -qP 'base\.yml\?ref=v[0-9]+\.[0-9]+\.[0-9]+' README.md docs
! rg -qP 'github>Gildraen/dx#v[0-9]+\.[0-9]+\.[0-9]+' README.md docs

# dx-mcp image contract (actual behavior, not just static text).
bash .devcontainer/test/dx/test-dx-mcp-image.sh
bash .devcontainer/test/dx/test-task-doctor.sh
bash .devcontainer/test/dx/test-resource-discovery.sh
