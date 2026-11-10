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
assert.equal(feature.containerEnv.DX_HOME, '/opt/dx');
assert.equal(devcontainer.remoteEnv.DX_HOME, undefined);
assert.equal(devcontainer.initializeCommand, 'git submodule update --init --recursive');
for (const component of ['agents', 'tools']) {
  const home = `DX_${component.toUpperCase()}_HOME`;
  const directory = `.devcontainer/components/${component}`;
  assert.equal(feature.containerEnv[home], `/opt/dx/components/${component}`);
  assert.equal(devcontainer.remoteEnv[home], '${containerWorkspaceFolder}/' + directory);
  const version = feature.options[`${component}Version`].default;
  assert.match(version, /^v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/);
  const resolved = execFileSync('git', ['-C', directory, 'rev-parse', `${version}^{commit}`], { encoding: 'utf8' }).trim();
  const entry = execFileSync('git', ['ls-files', '--stage', '--', directory], { encoding: 'utf8' }).trim();
  assert.equal(entry, `160000 ${resolved} 0\t${directory}`);
  assert.equal(execFileSync('git', ['-C', directory, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(), resolved);
  const url = execFileSync('git', ['config', '-f', '.gitmodules', '--get', `submodule.${directory}.url`], { encoding: 'utf8' }).trim();
  assert.equal(url, `https://github.com/Gildraen/dx-${component}.git`);
  const installer = fs.readFileSync('.devcontainer/src/dx/install.sh', 'utf8');
  assert.ok(installer.includes(`${component.toUpperCase()}VERSION:-${version}`), `installer default differs: ${component}`);
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
const installer = fs.readFileSync('.devcontainer/src/dx/install.sh', 'utf8');
assert.doesNotMatch(installer, /_REMOTE_USER_HOME|\.copilot|link_resource/);
assert.doesNotMatch(installer, /\.agents\/agents/);
EOF

echo "DX integration: component homes, discovery, bootstrap and submodule pins pass"
