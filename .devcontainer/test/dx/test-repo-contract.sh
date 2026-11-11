#!/usr/bin/env bash
# Non-Feature dx test suite: devcontainer config, Feature manifest, and doc/workflow pins.
# Assumes it is run from the repo root (as Task does).
set -euo pipefail

for script in .devcontainer/src/dx/install.sh .devcontainer/src/dx/dx-mcp .devcontainer/test/dx/*.sh; do
  bash -n "$script"
done

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

for workflow in validate devcontainer-test maintenance; do
  npx --yes js-yaml ".github/workflows/reusable-$workflow.yml" | node -e '
    const assert = require("node:assert/strict");
    const fs = require("node:fs");
    const workflow = JSON.parse(fs.readFileSync(0, "utf8"));
    const name = process.argv[1];
    const jobs = Object.values(workflow.jobs);
    assert.equal(jobs.length, 1);
    const job = jobs[0];
    assert.equal(job.uses, `Gildraen/ci-workflows/.github/workflows/reusable-${name}.yml@b8cc1c66c153e49887f0c63baa4a1aa238998b10`);
    const source = fs.readFileSync(`.github/workflows/reusable-${name}.yml`, "utf8");
    assert.ok(source.includes("@b8cc1c66c153e49887f0c63baa4a1aa238998b10 # v0.1.0-rc.1"));
    assert.equal(job.steps, undefined);
    assert.equal(job["runs-on"], undefined);
    const inputs = Object.keys(workflow.on.workflow_call?.inputs ?? {});
    assert.deepEqual(Object.keys(job.with ?? {}).sort(), inputs.sort());
    for (const input of inputs) assert.equal(job.with[input], "${{ inputs." + input + " }}");
  ' "$workflow"
done

node <<'EOF'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const feature = require('./.devcontainer/src/dx/devcontainer-feature.json');
const consumer = fs.readFileSync('docs/consumer.md', 'utf8');
assert.match(feature.version, /^\d+\.\d+\.\d+$/);
assert.ok(consumer.includes('ghcr.io/gildraen/dx/dx:<released-version>'));
for (const component of ['agents', 'tools']) {
  assert.ok(consumer.includes(feature.options[`${component}Version`].default));
  assert.ok(consumer.includes(feature.options[`${component}Commit`].default));
}
EOF
echo "DX repository: Feature, consumer docs and pinned CI facades pass"
