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
bash -n .devcontainer/test/dx/test-runtime-hierarchy.sh
bash .devcontainer/test/dx/test-runtime-hierarchy.sh

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
node <<'EOF'
const fs = require('node:fs');
const path = require('node:path');
const agentRoot = '.devcontainer/src/dx/runtime/agents';
const skillRoot = '.devcontainer/src/dx/runtime/skills';
for (const file of fs.readdirSync(agentRoot)) {
  const contents = fs.readFileSync(path.join(agentRoot, file), 'utf8');
  for (const match of contents.matchAll(/`([a-z][a-z0-9]*(?:-[a-z0-9]+)+)`/g)) {
    const skillPath = path.join(skillRoot, match[1], 'SKILL.md');
    if (!fs.existsSync(skillPath)) throw new Error(`missing referenced skill: ${match[1]}`);
  }
}
EOF

# Devcontainer contract: use the default workspace bind mount.
node <<'EOF'
const devcontainer = require('./.devcontainer/devcontainer.json');
if (devcontainer.workspaceFolder != null || devcontainer.workspaceMount != null) process.exit(1);
if (devcontainer.mounts != null || devcontainer.postCreateCommand != null) process.exit(1);
if (devcontainer.remoteEnv.HOST_PROJECT_PATH != null) process.exit(1);
if (devcontainer.remoteEnv.GH_CONFIG_DIR != null) process.exit(1);
if (devcontainer.remoteEnv.GIT_SSH_COMMAND != null || devcontainer.remoteEnv.DX_SSH_DIR != null) process.exit(1);
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

node <<'EOF'
const assert = require('node:assert/strict');
const feature = require('./.devcontainer/src/dx/devcontainer-feature.json');
assert.equal(feature.containerEnv.GH_CONFIG_DIR, '/var/lib/dx/devcontainer/.gh');
assert.deepEqual(feature.mounts, [{
  source: '${localWorkspaceFolder}/.devcontainer',
  target: '/var/lib/dx/devcontainer',
  type: 'bind',
}]);
assert.equal(feature.containerEnv.GIT_SSH_COMMAND, undefined);
assert.equal(feature.postStartCommand, undefined);
EOF

# CI contract: DX calls the separately versioned workflows from the published repository.
grep -qF 'Gildraen/ci-workflows/.github/workflows/reusable-validate.yml@v1.0.0' .github/workflows/validate.yml
grep -qF 'Gildraen/ci-workflows/.github/workflows/reusable-devcontainer-test.yml@v1.0.0' .github/workflows/validate.yml
grep -qF 'Gildraen/ci-workflows/.github/workflows/reusable-maintenance.yml@v1.0.0' .github/workflows/maintenance.yml

# Doc version contract: docs must reference the Feature's actual released version (from the manifest), never a stale or floating tag.
feature_version="$(node -p "require('./.devcontainer/src/dx/devcontainer-feature.json').version")"
rg -qF "ghcr.io/gildraen/dx/dx:${feature_version}" docs/consumer.md
! rg -q 'Gildraen/dx/\.github/workflows/reusable-(validate|devcontainer-test|maintenance)\.yml' README.md docs
rg -qF 'Gildraen/ci-workflows/.github/workflows/reusable-validate.yml@v1.0.0' docs/consumer.md
rg -qF 'Gildraen/ci-workflows/.github/workflows/reusable-maintenance.yml@v1.0.0' docs/consumer.md
! rg -qP 'base\.yml\?ref=v[0-9]+\.[0-9]+\.[0-9]+' README.md docs

# dx-mcp image contract (actual behavior, not just static text).
bash .devcontainer/test/dx/test-dx-mcp-image.sh
bash .devcontainer/test/dx/test-task-doctor.sh
bash .devcontainer/test/dx/test-resource-discovery.sh
