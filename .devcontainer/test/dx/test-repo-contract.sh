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
    assert.equal(job.uses, `Gildraen/ci-workflows/.github/workflows/reusable-${name}.yml@62f1721ea92ffd7275f4e4e2c60727b486d7def1`);
    const source = fs.readFileSync(`.github/workflows/reusable-${name}.yml`, "utf8");
    assert.ok(source.includes("@62f1721ea92ffd7275f4e4e2c60727b486d7def1 # v0.1.0"));
    assert.equal(job.steps, undefined);
    assert.equal(job["runs-on"], undefined);
    assert.equal(workflow.on.workflow_call?.secrets, undefined);
    assert.equal(job.secrets, undefined);
    const inputs = Object.keys(workflow.on.workflow_call?.inputs ?? {});
    assert.deepEqual(Object.keys(job.with ?? {}).sort(), inputs.sort());
    for (const input of inputs) assert.equal(job.with[input], "${{ inputs." + input + " }}");
  ' "$workflow"
done

for workflow in validate maintenance; do
  npx --yes js-yaml ".github/workflows/$workflow.yml" | node -e '
    const assert = require("node:assert/strict");
    const fs = require("node:fs");
    const workflow = JSON.parse(fs.readFileSync(0, "utf8"));
    const name = process.argv[1];
    for (const [jobName, job] of Object.entries(workflow.jobs)) {
      if (name === "validate" && jobName === "release") {
        assert.equal(job.secrets["release-please-token"],
          "${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}");
      } else {
        assert.equal(job.secrets, undefined);
      }
    }
  ' "$workflow"
done

node <<'EOF'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const feature = require('./.devcontainer/src/dx/devcontainer-feature.json');
const renovate = require('./renovate.json');
const releaseConfig = require('./release-please-config.json');
const releaseManifest = require('./.release-please-manifest.json');
const consumer = fs.readFileSync('docs/consumer.md', 'utf8');
assert.match(feature.version, /^\d+\.\d+\.\d+$/);
assert.deepEqual(feature.options, {});
assert.deepEqual(renovate.extends, ['github>Gildraen/renovate-config#0.2.0']);
assert.equal(renovate['git-submodules'], undefined);
assert.ok(consumer.includes('ghcr.io/gildraen/dx/dx:<released-version>'));
assert.equal(releaseConfig['include-v-in-tag'], false);
assert.equal(releaseConfig['bootstrap-sha'], 'b27495c93afc79cd6cba5a481bf6013ce2284279');
assert.equal(releaseConfig.packages['.']['version-file'], 'version.txt');
assert.deepEqual(releaseConfig.packages['.']['extra-files'], [{
  type: 'json',
  path: '.devcontainer/src/dx/devcontainer-feature.json',
  jsonpath: '$.version',
}]);
assert.equal(releaseManifest['.'], '1.3.0');
assert.equal(feature.version, releaseManifest['.']);
assert.equal(fs.readFileSync('version.txt', 'utf8').trim(), releaseManifest['.']);
const validateWorkflow = fs.readFileSync('.github/workflows/validate.yml', 'utf8');
const releaseWorkflow = fs.readFileSync('.github/workflows/release-please.yml', 'utf8');
assert.match(releaseWorkflow, /workflows: \[validate\]/);
assert.match(releaseWorkflow, /types: \[completed\]/);
assert.match(releaseWorkflow, /branches: \[main\]/);
assert.match(releaseWorkflow, /if: github\.event\.workflow_run\.conclusion == 'success'/);
assert.match(releaseWorkflow, /permissions:\n      contents: write\n      issues: write\n      pull-requests: write/);
assert.match(releaseWorkflow, /reusable-release-please\.yml@b04cfb98139aa06de661c70a128452184f2004dd # 0\.2\.0/);
assert.match(releaseWorkflow, /config-file: release-please-config\.json/);
assert.match(releaseWorkflow, /manifest-file: \.release-please-manifest\.json/);
assert.match(releaseWorkflow, /target-branch: main/);
assert.match(releaseWorkflow, /expected-sha: \$\{\{ github\.event\.workflow_run\.head_sha \}\}/);
assert.match(releaseWorkflow, /release-please-token: \$\{\{ secrets\.RELEASE_PLEASE_TOKEN \|\| secrets\.GITHUB_TOKEN \}\}/);
assert.doesNotMatch(releaseWorkflow, /googleapis\/release-please-action/);
assert.doesNotMatch(validateWorkflow, /reusable-release-please|release-please-action/);
for (const component of ['agents', 'tools']) {
  assert.ok(!consumer.includes(`"${component}Version"`));
  assert.ok(!consumer.includes(`"${component}Commit"`));
}
EOF
echo "DX repository: Feature, consumer docs and pinned CI facades pass"
