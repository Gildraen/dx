#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
export workdir
mkdir -p "$workdir/feature" "$workdir/usr/local/bin"

for component in agents tools; do
  checkout="$workdir/upstream/$component"
  git init -q "$checkout"
  if [[ "$component" == agents ]]; then
    mkdir -p "$checkout/instructions" "$checkout/agents" "$checkout/skills"
    printf 'fixture agents\n' > "$checkout/AGENTS.md"
    for resource in instructions agents skills; do
      printf 'fixture resource\n' > "$checkout/$resource/fixture"
    done
  else
    mkdir -p "$checkout/bin" "$checkout/taskfiles"
    printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "fixture tools" "$@"' > "$checkout/bin/dx-mcp"
    chmod +x "$checkout/bin/dx-mcp"
    printf "version: '3'\n" > "$checkout/taskfiles/base.yml"
  fi
  git -C "$checkout" add .
  git -C "$checkout" -c user.name=dx-test -c user.email=dx-test@example.invalid -c commit.gpgsign=false commit -qm fixture
  git -C "$checkout" tag v1.2.3
done

agents_commit="$(git -C "$workdir/upstream/agents" rev-parse HEAD)"
tools_commit="$(git -C "$workdir/upstream/tools" rev-parse HEAD)"

node - "${DX_INSTALL_SOURCE:-$repo_root/.devcontainer/src/dx/install.sh}" "$workdir/feature/install.sh" "$workdir" "$agents_commit" "$tools_commit" <<'EOF'
const fs = require('node:fs');
const [sourcePath, targetPath, workdir, agentsCommit, toolsCommit] = process.argv.slice(2);
let source = fs.readFileSync(sourcePath, 'utf8');
const replacements = [
  ['agents_version="v0.1.0"', 'agents_version="v1.2.3"'],
  ['agents_commit="2bc43f5c09a2d8676288de3470cd890ed4c08448"', `agents_commit="${agentsCommit}"`],
  ['tools_version="v0.1.0"', 'tools_version="v1.2.3"'],
  ['tools_commit="f7b5a41f48026571cafe3e7d287dd0234db9c0b6"', `tools_commit="${toolsCommit}"`],
];
for (const [expected, replacement] of replacements) {
  if (!source.includes(expected)) throw new Error(`installer pin changed: ${expected}`);
  source = source.replace(expected, replacement);
}
if (!source.includes('/opt/dx') || !source.includes('/usr/local/bin')) {
  throw new Error('installer fixture paths no longer match');
}
fs.writeFileSync(targetPath, source.replaceAll('/opt/dx', `${workdir}/installed`)
  .replaceAll('/usr/local/bin', `${workdir}/usr/local/bin`));
EOF
cp "$repo_root/.devcontainer/src/dx/dx-mcp" "$workdir/feature/dx-mcp"

export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_ALLOW_PROTOCOL=file
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0="url.file://$workdir/upstream/agents.insteadOf"
export GIT_CONFIG_VALUE_0=https://github.com/Gildraen/dx-agents.git
export GIT_CONFIG_KEY_1="url.file://$workdir/upstream/tools.insteadOf"
export GIT_CONFIG_VALUE_1=https://github.com/Gildraen/dx-tools.git

bash "$workdir/feature/install.sh" > "$workdir/install.log" 2>&1 || { cat "$workdir/install.log" >&2; exit 1; }
test -f "$workdir/installed/components/agents/AGENTS.md"
test -x "$workdir/installed/components/tools/bin/dx-mcp"
for resource in AGENTS.md instructions agents skills bin taskfiles; do
  component=agents
  [[ "$resource" != bin && "$resource" != taskfiles ]] || component=tools
  test -L "$workdir/installed/$resource"
  [[ "$(readlink "$workdir/installed/$resource")" == "components/$component/$resource" ]]
  test -e "$workdir/installed/$resource"
done
test ! -e "$workdir/installed/components/agents/.git"
test ! -e "$workdir/installed/components/tools/.git"
test -x "$workdir/usr/local/bin/dx-mcp"
cmp "$workdir/feature/dx-mcp" "$workdir/usr/local/bin/dx-mcp"
output="$(DX_TOOLS_HOME="$workdir/installed/components/tools" "$workdir/usr/local/bin/dx-mcp" github --help)"
[[ "$output" == $'fixture tools\ngithub\n--help' ]]

write_installer_variant() {
  local variant="$1" expected="$2" replacement="$3"
  node - "$workdir/feature/install.sh" "$workdir/$variant" "$expected" "$replacement" <<'EOF'
const fs = require('node:fs');
const [sourcePath, targetPath, expected, replacement] = process.argv.slice(2);
const source = fs.readFileSync(sourcePath, 'utf8');
if (!source.includes(expected)) throw new Error(`installer pin not found: ${expected}`);
fs.writeFileSync(targetPath, source.replace(expected, replacement));
EOF
}

write_installer_variant invalid-version.sh 'agents_version="v1.2.3"' 'agents_version="invalid-ref"'
if bash "$workdir/invalid-version.sh" > "$workdir/invalid.log" 2>&1; then
  printf 'Installer accepted an invalid version tag\n' >&2
  exit 1
fi
grep -Fq 'invalid-ref' "$workdir/invalid.log"

write_installer_variant invalid-commit.sh "agents_commit=\"$agents_commit\"" 'agents_commit="invalid-ref"'
if bash "$workdir/invalid-commit.sh" > "$workdir/invalid.log" 2>&1; then
  printf 'Installer accepted an invalid commit SHA\n' >&2
  exit 1
fi
grep -Fq 'Invalid commit SHA for agents' "$workdir/invalid.log"

write_installer_variant mismatched-pair.sh "agents_commit=\"$agents_commit\"" "agents_commit=\"$tools_commit\""
if bash "$workdir/mismatched-pair.sh" > "$workdir/mismatch.log" 2>&1; then
  printf 'Installer accepted a tag and commit SHA that do not match\n' >&2
  exit 1
fi
grep -Fq 'does not match' "$workdir/mismatch.log"

for component in agents tools; do
  printf 'stale\n' > "$workdir/installed/components/$component/stale"
done
bash "$workdir/feature/install.sh" > "$workdir/install.log" 2>&1 || { cat "$workdir/install.log" >&2; exit 1; }
for component in agents tools; do
  if [[ -e "$workdir/installed/components/$component/stale" ]]; then
    printf 'Installer retained stale files in component: %s\n' "$component" >&2
    exit 1
  fi
done

printf 'Installer: tag/SHA pairs, component snapshots, six symlinks, wrapper, replacement and invalid refs pass\n'