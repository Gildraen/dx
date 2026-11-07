# Consuming `dx`

This guide covers installing and configuring `dx` in a repository. For
working on `dx` itself using a real project as a testbed, see
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
Feature does not provide those tools.

The [Feature manifest](../.devcontainer/src/dx/devcontainer-feature.json)
declares Node.js LTS, GitHub CLI, Go Task 3.53.1, Git, `jq`, ripgrep and
`libatomic1`. Check the manifest of the selected release before relying on a
tool; requirements not included there remain project-specific.

The Feature copies the versioned DX runtime to `/opt/dx` and sets
`DX_HOME=/opt/dx` through `containerEnv`: the `AGENTS.md` entry point, shared
instructions, roles, skills, the portable `dx-mcp` launcher, and Task helpers.
This environment variable alone does not configure an AI client. The installed
runtime is a snapshot; to consume shared resource changes, update the Feature
release and rebuild the container. For live sources, use [dogfood.md](dogfood.md).
The launcher runs GitHub's pinned official MCP image through Docker and does
not manage a GitHub token. A project that enables MCP must provide Docker
access and configure its MCP client separately. Renovate proposes updates to
the image pin; the launcher has no per-consumer image setting. DX does not
authenticate the GitHub CLI automatically.

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
`gh` creates `.gh` when it writes configuration.

Files live directly in the host's `.devcontainer/.gh` and survive container
rebuilds and workspace moves if those files are retained. Existing host state
at that location is reused directly. Ownership and permissions come from the
host filesystem. This is `gh` configuration and may contain tokens; it is not
SSH private-key storage. Consumers must ensure the remote user
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

Remote Taskfiles require Go Task 3.53.1 or newer. The DX Feature and reusable
validation workflow both provide a compatible release.

The reusable validation workflow installs a compatible Task release on its GitHub
Actions runner before executing `task validate`. Its availability in CI does
not mean that the local devcontainer already provides it.

The consumer ref must exist in Git before the consumer is used; publishing the
Feature does not create Git tags. CI downloads that exact ref and trusts only `github.com` through
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
regex-based custom manager defined in [default.json](../default.json)).

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
needed. It then asks the agent to list `$DX_HOME/agents/*.agent.md` and
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
is the client-neutral loading procedure. The Feature also adds `.agents/agents/`
to the VS Code agent picker through `chat.agentFilesLocations`. This setting
requires `.agent.md` files in custom directories such as `.agents/agents/`;
plain `.md` files are recognized only in VS Code's native agent folders.
Copilot CLI and the Copilot app do not inherit this VS Code setting.
The Feature does not install shared DX resources
into Copilot user directories. The DX checkout adds its
source runtime path to `chat.agentFilesLocations` through
`.devcontainer/devcontainer.json`; consumer repositories do not inherit that
checkout-specific path. Consumers use the explicit runtime bootstrap for
shared resources. Native discovery of shared roles requires client support and
client-specific configuration; `DX_HOME` alone does not configure it.

Outside VS Code, neither `DX_HOME` nor these files guarantees a native role
picker, automatic instruction or skill loading, or subagent support. If the
client does not read the root `AGENTS.md`, attach it explicitly through the
context or initial request before starting work. For example:

```text
Read the project's AGENTS.md provided in context. Resolve DX_HOME from the
environment (default /opt/dx when absent), read its AGENTS.md and referenced
rules, then list `$DX_HOME/agents/*.agent.md`, `$DX_HOME/skills/*/SKILL.md`,
`.agents/agents/*.agent.md`, and `.agents/skills/*/SKILL.md`. Select relevant
resources from their metadata and load them before proceeding.
```

Instructions are guidance, not a security enforcement boundary; use execution
permissions and isolation for enforcement. The runtime requests delegation,
but a managed subagent tool and its permissions depend on the client. When
subagents are unavailable, apply the selected role in the current agent and
report that fallback.

## 6. GitHub MCP client

Configure your MCP client's stdio server command as `dx-mcp` with the argument
`github`. The launcher requires a Docker CLI and accessible daemon, starts the
official GitHub MCP server with OAuth, and binds its callback port to
`127.0.0.1:8085`. Ensure this port is available and the authentication flow can
reach it in your environment. MCP client configuration belongs to the project
or client, not to the shared agent bootstrap.

GitHub MCP OAuth authentication is separate from Git/SSH and `gh`
authentication. The launcher does not forward `GH_TOKEN` or `GITHUB_TOKEN` to
the server. Configure application-level client access separately from runtime
resource loading through `DX_HOME`.

## Runtime state that never belongs in `dx` or in your repository

Tokens, `gh` auth state, and generated MCP configuration are runtime state,
never versioned DX or consumer content. DX provides a default `gh`
configuration location backed by the host's `.devcontainer` bind mount, not
credentials. The consumer owns its storage permissions and Git ignore rules.
Treat generated machine-specific client settings as potentially secret;
inspect their handling locally and keep authentication state out of Git and
container images.
