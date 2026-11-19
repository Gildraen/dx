#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"

node <<'EOF'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { execFileSync } = require('node:child_process');
const feature = require('./.devcontainer/src/dx/devcontainer-feature.json');
const devcontainer = require('./.devcontainer/devcontainer.json');
const installer = fs.readFileSync('.devcontainer/src/dx/install.sh', 'utf8');
assert.equal(feature.containerEnv.DX_HOME, '/opt/dx');
assert.deepEqual(feature.options, {});
assert.equal(devcontainer.remoteEnv.DX_HOME, undefined);
assert.equal(devcontainer.initializeCommand, 'git submodule update --init --recursive');
for (const component of ['agents', 'tools']) {
  const home = `DX_${component.toUpperCase()}_HOME`;
  const directory = `.devcontainer/components/${component}`;
  assert.equal(feature.containerEnv[home], `/opt/dx/components/${component}`);
  assert.equal(devcontainer.remoteEnv[home], '${containerWorkspaceFolder}/' + directory);
  const version = installer.match(new RegExp(`^${component}_version="([^"]+)"$`, 'm'))?.[1];
  const commit = installer.match(new RegExp(`^${component}_commit="([^"]+)"$`, 'm'))?.[1];
  assert.ok(version, `installer must fix the ${component} version`);
  assert.ok(commit, `installer must fix the ${component} commit`);
  assert.match(version, /^v(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$/);
  assert.match(commit, /^[0-9a-f]{40}$/);
  const tagRefs = execFileSync('git', ['-C', directory, 'ls-remote', 'origin', `refs/tags/${version}`, `refs/tags/${version}^{}`], { encoding: 'utf8' })
    .trim().split('\n').map(line => line.split('\t'));
  const resolved = tagRefs.find(([, ref]) => ref === `refs/tags/${version}^{}`)?.[0]
    ?? tagRefs.find(([, ref]) => ref === `refs/tags/${version}`)?.[0];
  assert.equal(resolved, commit, `${component} tag and commit SHA must match`);
  const entry = execFileSync('git', ['ls-files', '--stage', '--', directory], { encoding: 'utf8' }).trim();
  assert.equal(entry, `160000 ${resolved} 0\t${directory}`);
  assert.equal(execFileSync('git', ['-C', directory, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(), resolved);
  const url = execFileSync('git', ['config', '-f', '.gitmodules', '--get', `submodule.${directory}.url`], { encoding: 'utf8' }).trim();
  assert.equal(url, `https://github.com/Gildraen/dx-${component}.git`);
  const branch = execFileSync('git', ['config', '-f', '.gitmodules', '--get', `submodule.${directory}.branch`], { encoding: 'utf8' }).trim();
  assert.equal(branch, version, `${component} Renovate branch must match the installer tag`);
  const annotation = `# renovate: datasource=github-tags depName=${directory} packageName=Gildraen/dx-${component}\n${component}_version="${version}"\n${component}_commit="${commit}"`;
  assert.ok(installer.includes(annotation), `${component} installer pin must be annotated for Renovate`);
  assert.doesNotMatch(installer, new RegExp(`${component.toUpperCase()}VERSION|${component.toUpperCase()}COMMIT`));
}
for (const configuration of [feature, devcontainer]) {
  const settings = configuration.customizations?.vscode?.settings ?? {};
  if (configuration === feature) {
    assert.deepEqual(settings['chat.agentFilesLocations'], {
      '.agents/agents': true,
    });
  } else {
    assert.deepEqual(settings['chat.agentFilesLocations'], {
      '.agents/agents': true,
      '.devcontainer/components/agents/agents': true,
    });
  }
  assert.equal(settings['chat.agentSkillsLocations'], undefined);
  const extensions = configuration.customizations?.vscode?.extensions ?? [];
  assert.ok(extensions.every(extension => !/copilot/i.test(extension)));
}
assert.equal(devcontainer.customizations.vscode.settings['chat.permissions.default'], 'autopilot');
assert.ok(fs.readFileSync('AGENTS.md', 'utf8').includes('(.devcontainer/components/agents/AGENTS.md)'));
assert.ok(!fs.existsSync('.devcontainer/src/dx/runtime'), 'DX must not embed component sources');
assert.doesNotMatch(installer, /_REMOTE_USER_HOME|\.copilot|link_resource/);
assert.doesNotMatch(installer, /\.agents\/agents/);
EOF

echo "DX integration: component homes, discovery, bootstrap and submodule pins pass"
