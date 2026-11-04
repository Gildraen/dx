#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"

node <<'EOF'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const feature = require('./.devcontainer/src/dx/devcontainer-feature.json');
const devcontainer = require('./.devcontainer/devcontainer.json');
assert.equal(feature.containerEnv.DX_HOME, '/opt/dx');
assert.equal(devcontainer.remoteEnv.DX_HOME, '${containerWorkspaceFolder}/.devcontainer/src/dx/runtime');
for (const configuration of [feature, devcontainer]) {
  const settings = configuration.customizations?.vscode?.settings ?? {};
  if (configuration === feature) {
    assert.ok(Object.keys(settings).every(setting => !setting.startsWith('chat.')));
  }
  const extensions = configuration.customizations?.vscode?.extensions ?? [];
  assert.ok(extensions.every(extension => !/copilot/i.test(extension)));
}
assert.equal(devcontainer.customizations.vscode.settings['chat.permissions.default'], 'autopilot');
for (const directory of ['agents', 'instructions', 'skills']) {
  assert.ok(fs.statSync(`.devcontainer/src/dx/runtime/${directory}`).isDirectory());
}
for (const directory of ['agents', 'instructions']) {
  const root = `.devcontainer/src/dx/runtime/${directory}`;
  const files = fs.readdirSync(root);
  assert.ok(files.length > 0);
  for (const file of files) {
    assert.match(file, /^[a-z][a-z0-9-]*\.md$/);
    assert.doesNotMatch(fs.readFileSync(`${root}/${file}`, 'utf8'), /^applyTo:/m);
  }
}
const agentRoot = '.devcontainer/src/dx/runtime/agents';
const roleNames = new Set();
for (const file of fs.readdirSync(agentRoot)) {
  const contents = fs.readFileSync(`${agentRoot}/${file}`, 'utf8');
  const roleName = contents.match(/^name:\s*(.+)$/m)?.[1]?.trim();
  assert.ok(roleName, `missing role name: ${file}`);
  assert.ok(!roleNames.has(roleName), `duplicate role name: ${roleName}`);
  roleNames.add(roleName);
}
const bootstrap = fs.readFileSync('.devcontainer/src/dx/runtime/AGENTS.md', 'utf8');
assert.ok(bootstrap.includes('(instructions/base.md)'));
assert.ok(bootstrap.includes('(instructions/git.md)'));
assert.ok(bootstrap.includes('agents/'));
assert.ok(bootstrap.includes('skills/*/SKILL.md'));
assert.ok(bootstrap.includes('If the client cannot run a subagent'));
assert.ok(bootstrap.includes('## Instruction hierarchy'));
const inheritedReminder = /\bAGENTS\.md\b|\b(?:base|git)(?:\.instructions)?\.md\b|instructions?\s+partag[eé]es?/i;
for (const directory of ['agents', 'skills']) {
  const root = `.devcontainer/src/dx/runtime/${directory}`;
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    if (directory === 'skills' && !entry.isDirectory()) continue;
    const resource = entry.isDirectory() ? `${root}/${entry.name}/SKILL.md` : `${root}/${entry.name}`;
    assert.doesNotMatch(fs.readFileSync(resource, 'utf8'), inheritedReminder, resource);
  }
}
assert.ok(fs.readFileSync('AGENTS.md', 'utf8').includes('(.devcontainer/src/dx/runtime/AGENTS.md)'));
assert.doesNotMatch(fs.readFileSync('.devcontainer/src/dx/install.sh', 'utf8'), /copilot|\.claude|\.github\/agents/i);
EOF

echo "DX runtime configuration is independent of the AI client"
