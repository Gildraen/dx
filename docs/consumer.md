# Consuming `dx`

This describes how a repository consumes the stable, released version of
`dx`. For working on `dx` itself using a real project as a testbed, see
[dogfood.md](dogfood.md).

## 1. Dev Container Feature

Compose the official Features you need with the shared `dx` Feature:

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "my-project",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
  "features": {
    "ghcr.io/gildraen/dx/dx:1.2.0": {}
  }
}
```

Only add other Features or packages for project-specific requirements
(Docker-outside-of-Docker, project language runtimes, service CLIs, …). The DX
common tool baseline is deliberately limited and does not cover those tools.

The tool baseline is defined by the selected DX Feature's manifest. Check that
manifest before relying on a tool; requirements not included there remain
project-specific.

The Feature copies the versioned DX runtime to `/opt/dx` and sets
`DX_HOME=/opt/dx` through `containerEnv`: the `AGENTS.md` entry point, shared
instructions, roles, skills, the portable `dx-mcp` launcher, and Task helpers.
This environment variable alone does not configure an AI client. The installed
runtime is a snapshot; to consume shared resource changes, update the Feature
release and rebuild the container. For live sources, use [dogfood.md](dogfood.md).
The launcher runs GitHub's pinned official MCP image through Docker and does
not manage a GitHub token. A project that enables MCP must provide Docker
access separately until the `.agents/mcp.json` contract is defined. Renovate
keeps this pin current; the image is not configurable per consumer. The Dev Container keeps
the GitHub CLI available; DX does not authenticate it automatically.

### Git credentials and GitHub CLI state

Git uses native [VS Code Dev Containers credential sharing](https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials):
the extension copies the host's `.gitconfig`, reuses its credential helper for
HTTPS, and forwards a running host SSH agent. Configure Git identity and
credentials on the host. DX does not set `GIT_SSH_COMMAND`, generate SSH keys,
or authenticate Git automatically.

The Feature sets `containerEnv.GH_CONFIG_DIR=/var/lib/dx/devcontainer/.gh`
and declares this bind mount:

```json
{
  "source": "${localWorkspaceFolder}/.devcontainer",
  "target": "/var/lib/dx/devcontainer",
  "type": "bind"
}
```

The host workspace root must contain `.devcontainer`. Consumers with Dev
Container configurations elsewhere must adapt the mounts in their own
configuration; the source is not resolved relative to `devcontainer.json`.
DX uses no named volume, directory preparation in `install.sh`, state copy,
helper script, or startup command for this storage. `gh` creates `.gh` when
it writes configuration.

Files live directly in the host's `.devcontainer/.gh` and survive container
rebuilds and workspace moves if those files are retained. Existing host state
at that location is reused directly; no migration is needed. Ownership and
permissions come from the host filesystem, not a DX UID adjustment. Windows
mounts may expose mode `777`; DX does not guarantee mode `700`. This is `gh`
configuration, not an SSH private key. Consumers must ensure the remote user
can write to the mounted directory. To use other storage, override
`GH_CONFIG_DIR` through `remoteEnv` and manage that storage in the consumer.

For GitHub API access through `gh`, run `gh auth login` only when neither
`GH_TOKEN` nor `GITHUB_TOKEN` nor existing authentication state is available.
This authentication is distinct from Git/SSH credentials. For GitHub HTTPS
only, if no credential helper is configured and you explicitly want Git to
reuse `gh` authentication, run `gh auth setup-git`. DX does not run it or
overwrite an existing helper automatically.

Without a keyring, `gh` may store tokens in plaintext: treat this directory
as secret storage, never commit its state or bake it into an image. The
consumer must exclude it from Git, either with a parent ignore rule or a
consumer-provided `.devcontainer/.gh/.gitignore` containing:

```gitignore
*
!.gitignore
```

DX does not create this ignore file. Any alternative workspace storage must
also be ignored by Git.

## 2. Reusable GitHub workflows

```yaml
# .github/workflows/validate.yml
name: validate
on:
  pull_request:
jobs:
  validate:
    uses: Gildraen/dx/.github/workflows/reusable-validate.yml@<released-tag>
```

The reusable workflow runs `task validate` (configurable via the `task-name`
input) in your repository. Your `Taskfile.yml` defines what `validate` (and
`test`, `lint`, …) means for your stack — `dx` only enforces the contract,
not the implementation. It sets `TASK_REMOTE_TRUSTED_HOSTS=github.com` for
the remote DX Taskfile, avoiding an interactive trust prompt in CI without
enabling global `--yes` behavior.

Same pattern for maintenance / link-checking:
`Gildraen/dx/.github/workflows/reusable-maintenance.yml@<released-tag>`.

## 3. Remote Taskfile (optional shared helpers)

```yaml
# Taskfile.yml
includes:
  dx: https://github.com/Gildraen/dx.git//.devcontainer/src/dx/runtime/taskfiles/base.yml?ref=<released-tag>
```

Gives you `task dx:doctor` and `task dx:mcp:github`.
`task dx:doctor` checks the runtime offline, not authentication.
Your own `validate`/`test`/`lint` tasks stay in your Taskfile.

Remote Taskfiles require a Go Task release with remote include support. The DX
Feature and reusable validation workflow both provide a compatible release.

The reusable validation workflow installs a compatible Task release on its GitHub
Actions runner before executing `task validate`. Its availability in CI does
not mean that the local devcontainer already provides it.

The consumer ref must match an existing DX release tag before the consumer is
used. CI downloads that exact ref and trusts only `github.com` through
`TASK_REMOTE_TRUSTED_HOSTS=github.com`.

## 4. Renovate preset

```jsonc
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>Gildraen/dx#<released-tag>"]
}
```

Renovate then proposes updates to: the `dx` Feature version in
`devcontainer.json` (native devcontainer manager), reusable workflow refs
(native github-actions manager), and the Remote Taskfile ref (a single
regex-based custom manager, documented in `default.json`, kept because Task
has no native Renovate manager).

## 5. Agents and skills

Keep the root `AGENTS.md` small: a bootstrap plus genuinely project-specific
rules. The runtime does not require a particular AI client, model, or editor.
Use this bootstrap in the consumer:

````markdown
# Project agent instructions

Before any work, resolve DX_HOME from the process environment; use /opt/dx
only when DX_HOME is absent. Read its AGENTS.md and follow the shared guidance.

## Project-specific rules
...
````

Common loading, selection, and delegation rules belong to the runtime's
`AGENTS.md`, not to each project bootstrap, role, or skill.

The runtime's `AGENTS.md` explicitly loads `instructions/base.md` and
`instructions/git.md` before work; no editor-specific activation metadata is
needed. It then asks the agent to list `$DX_HOME/agents/*.md` and
`$DX_HOME/skills/*/SKILL.md`, inspect `name` and `description` metadata, and
read the selected role or workflow before applying it. Directory contents are
the authoritative list, not a catalog in this guide.

Shared sources live under `.devcontainer/src/dx/runtime/` in `dx` and are
installed by the Feature. Project-specific roles and skills remain additive
under `.agents/agents/` and `.agents/skills/` in the consumer. These are
the sole canonical project locations. Do not keep duplicate project resources
in client-specific directories. The Feature installs the runtime guide under
`DX_HOME`; after the consumer's root `AGENTS.md` loads that guide, it explicitly
inspects both project paths and selects relevant resources by metadata. This
directs prompt loading for every client. The Feature also adds `.agents/agents/`
to the VS Code agent picker through `chat.agentFilesLocations`. This setting
is supported, not deprecated, but is VS Code-specific; Copilot CLI and the
Copilot app do not inherit it. `chat.agentSkillsLocations` is deprecated as
VS Code moves skills to harness-native locations; editor-only skill search
paths are not portable, so DX does not set it. Instead, the Feature links
shared DX resources from `DX_HOME` into the container user's native
`~/.copilot/agents/` and `~/.copilot/skills/` directories. These are symlinks
inside the container home, not writes to the host `.agents` or copies of the
canonical resources. If a user already has an entry at a shared resource's
destination, the Feature preserves it and skips that link. Other clients use
the explicit runtime bootstrap. Do not copy shared content into the workspace
or generate additional resource copies.

Outside VS Code, neither `DX_HOME` nor these files guarantees a native role
picker, automatic instruction or skill loading, or subagent support. If the
client does not read the root `AGENTS.md`, attach it explicitly through the
context or initial request before starting work. For example:

```text
Read the project's AGENTS.md provided in context. Resolve DX_HOME from the
environment (default /opt/dx when absent), read its AGENTS.md and referenced
rules, then list `$DX_HOME/agents/*.md`, `$DX_HOME/skills/*/SKILL.md`,
`.agents/agents/*.md`, and `.agents/skills/*/SKILL.md`. Select relevant
resources from their metadata and load them before proceeding.
```

Instructions are guidance, not a security enforcement boundary; use execution
permissions and isolation for enforcement.

`.agents/mcp.json` is reserved for a future MCP configuration standard. Do not
add one until that contract is documented in `dx`.

## Runtime state that never belongs in `dx` or in your repository

Tokens, `gh` auth state, and generated MCP configuration are runtime state,
never versioned DX or consumer content. DX provides a default `gh`
configuration location backed by the host's `.devcontainer` bind mount, not
credentials. The consumer owns its storage permissions and Git ignore rules.
The official GitHub MCP server's local stdio OAuth flow keeps its token in
memory only, so no MCP token file or workspace state directory is required.
DX uses OAuth as its single MCP authentication mode.
