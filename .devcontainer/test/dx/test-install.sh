#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
export workdir
mkdir -p "$workdir/feature" "$workdir/usr/local/bin"

node - "${DX_INSTALL_SOURCE:-$repo_root/.devcontainer/src/dx/install.sh}" "$workdir/feature/install.sh" <<'EOF'
const fs = require('node:fs');
const source = fs.readFileSync(process.argv[2], 'utf8');
if (!source.includes('/opt/dx') || !source.includes('/usr/local/bin')) throw new Error('installer fixture paths no longer match');
fs.writeFileSync(process.argv[3], source.replaceAll('/opt/dx', `${process.env.workdir}/installed`)
  .replaceAll('/usr/local/bin', `${process.env.workdir}/usr/local/bin`));
EOF
cp "$repo_root/.devcontainer/src/dx/dx-mcp" "$workdir/feature/dx-mcp"

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

export AGENTSVERSION=v1.2.3
export AGENTSCOMMIT="$(git -C "$workdir/upstream/agents" rev-parse HEAD)"
export TOOLSVERSION=v1.2.3
export TOOLSCOMMIT="$(git -C "$workdir/upstream/tools" rev-parse HEAD)"
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

for component in agents tools; do
  version_variable="${component^^}VERSION"
  commit_variable="${component^^}COMMIT"
  if env "$version_variable=invalid-ref" bash "$workdir/feature/install.sh" > "$workdir/invalid.log" 2>&1; then
    printf 'Installer accepted an invalid version tag for: %s\n' "$component" >&2
    exit 1
  fi
  grep -Fq 'invalid-ref' "$workdir/invalid.log"
  if env "$commit_variable=invalid-ref" bash "$workdir/feature/install.sh" > "$workdir/invalid.log" 2>&1; then
    printf 'Installer accepted an invalid commit SHA for: %s\n' "$component" >&2
    exit 1
  fi
  grep -Fq "Invalid commit SHA for $component" "$workdir/invalid.log"
done

if AGENTSCOMMIT="$TOOLSCOMMIT" bash "$workdir/feature/install.sh" > "$workdir/mismatch.log" 2>&1; then
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